#!/bin/bash
set -e

# Get configuration from Terraform outputs
EDGE_IP=$(terraform -chdir=terraform output -raw edge_public_ip)
MASTER_IP=$(terraform -chdir=terraform output -raw master_public_ip)
GCS_BUCKET=$(terraform -chdir=terraform output -raw gcs_bucket)
PROJECT_ROOT="/home/quydx/cloud-bigdata.project"
SSH_USER="ubuntu"
INPUT_FILE="large_sample.txt"

echo "Submitting WordCount job using Google Cloud Storage..."
echo ""
echo "GCS Bucket: gs://${GCS_BUCKET}"
echo ""

# Upload input file to GCS
echo "Step 1: Uploading input file to GCS..."
gsutil cp "${PROJECT_ROOT}/${INPUT_FILE}" gs://${GCS_BUCKET}/input/

echo "Verifying upload..."
gsutil ls -lh gs://${GCS_BUCKET}/input/${INPUT_FILE}

# Submit Spark job
echo ""
echo "Step 2: Submitting Spark job to cluster..."
ssh -o StrictHostKeyChecking=no ${SSH_USER}@${EDGE_IP} << ENDSSH
    export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_202
    export SPARK_HOME=/opt/spark
    export PATH=\$SPARK_HOME/bin:\$PATH
    
    # Remove old output
    echo "Cleaning old output..."
    gsutil -m rm -rf gs://${GCS_BUCKET}/output/wordcount 2>/dev/null || true
    
    # Submit Spark job reading from and writing to GCS
    echo ""
    echo "Submitting Spark WordCount job..."
    time spark-submit \
        --class org.apache.spark.examples.JavaWordCount \
        --master spark://10.128.0.5:7077 \
        --executor-memory 2g \
        --total-executor-cores 4 \
        --conf spark.eventLog.enabled=false \
        /opt/spark/examples/jars/spark-examples_2.11-2.4.3.jar \
        gs://${GCS_BUCKET}/input/${INPUT_FILE} \
        gs://${GCS_BUCKET}/output/wordcount
    
    echo ""
    echo "Job completed!"
ENDSSH

echo ""
echo "Step 3: Checking results in GCS..."
echo ""
echo "Output files:"
gsutil ls gs://${GCS_BUCKET}/output/wordcount/

echo ""
echo "Top 20 results:"
gsutil cat gs://${GCS_BUCKET}/output/wordcount/part-* | head -20

echo ""
echo "Total unique words:"
gsutil cat gs://${GCS_BUCKET}/output/wordcount/part-* | wc -l

echo ""
echo "Job submission completed!"
echo "Spark Master UI: http://$MASTER_IP:8080"
echo "GCS Console: https://console.cloud.google.com/storage/browser/${GCS_BUCKET}"
echo ""
echo "To view all results:"
echo "gsutil cat gs://${GCS_BUCKET}/output/wordcount/part-*"
