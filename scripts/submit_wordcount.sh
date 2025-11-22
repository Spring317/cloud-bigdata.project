#!/bin/bash
set -e

# Configuration
EDGE_IP="35.188.180.34"
MASTER_IP="35.222.73.137"
WORKER1_IP="136.112.234.105"
WORKER2_IP="35.238.187.33"
PROJECT_ROOT="$HOME/cloud-bigdata.project"
SSH_USER="ubuntu"
INPUT_FILE="large_sample.txt"

echo "Submitting WordCount job to Spark cluster..."
echo ""

# Get local file size for comparison
if [ -f "${PROJECT_ROOT}/${INPUT_FILE}" ]; then
    LOCAL_SIZE=$(stat -f%z "${PROJECT_ROOT}/${INPUT_FILE}" 2>/dev/null || stat -c%s "${PROJECT_ROOT}/${INPUT_FILE}" 2>/dev/null)
    echo "Local file size: $(echo $LOCAL_SIZE | numfmt --to=iec-i --suffix=B 2>/dev/null || echo ${LOCAL_SIZE} bytes)"
else
    echo "Error: ${INPUT_FILE} not found in ${PROJECT_ROOT}"
    exit 1
fi

# Function to check and copy file to a node with size verification
check_and_copy_file() {
    local NODE_IP=$1
    local NODE_NAME=$2
    
    echo ""
    echo "Checking $NODE_NAME ($NODE_IP)..."
    
    # Check if file exists and get its size
    REMOTE_SIZE=$(ssh -o StrictHostKeyChecking=no ${SSH_USER}@${NODE_IP} \
        "stat -c%s /tmp/${INPUT_FILE} 2>/dev/null || echo 0")
    
    if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ] 2>/dev/null; then
        echo "   File exists and size matches ($REMOTE_SIZE bytes)"
        return 0
    elif [ "$REMOTE_SIZE" -gt 0 ] 2>/dev/null; then
        echo "   File exists but size mismatch!"
        echo "      Local: $LOCAL_SIZE bytes, Remote: $REMOTE_SIZE bytes"
        echo "   Removing corrupted file..."
        ssh -o StrictHostKeyChecking=no ${SSH_USER}@${NODE_IP} "rm -f /tmp/${INPUT_FILE}"
    else
        echo "   File missing on $NODE_NAME"
    fi
    
    echo "   Copying file to $NODE_NAME (this may take a few minutes)..."
    scp -o StrictHostKeyChecking=no "${PROJECT_ROOT}/${INPUT_FILE}" ${SSH_USER}@${NODE_IP}:/tmp/
    
    # Verify after copy
    NEW_SIZE=$(ssh -o StrictHostKeyChecking=no ${SSH_USER}@${NODE_IP} \
        "stat -c%s /tmp/${INPUT_FILE} 2>/dev/null")
    
    if [ "$NEW_SIZE" -eq "$LOCAL_SIZE" ]; then
        echo "   File copied successfully and verified!"
    else
        echo "   Copy verification failed! Expected: $LOCAL_SIZE, Got: $NEW_SIZE"
        exit 1
    fi
}

# Check and copy to edge node
check_and_copy_file "$EDGE_IP" "Edge Node"

# Check and copy to worker nodes
check_and_copy_file "$WORKER1_IP" "Worker 1"
check_and_copy_file "$WORKER2_IP" "Worker 2"

echo ""
echo "All nodes have the correct input file!"
echo ""

# Submit job remotely
echo "Submitting Spark job..."
ssh -o StrictHostKeyChecking=no ${SSH_USER}@$EDGE_IP << 'ENDSSH'
    # Clean previous results
    rm -rf /tmp/wordcount_output* 2>/dev/null || true
    
    OUTPUT_DIR="/tmp/wordcount_output_$(date +%s)"

    echo 'Submitting WordCount job...'
    time /opt/spark/bin/spark-submit \
        --class org.apache.spark.examples.JavaWordCount \
        --master spark://10.128.0.5:7077\
        --executor-memory 2g \
        --total-executor-cores 4 \
        --conf spark.eventLog.enabled=false \
        /opt/spark/examples/jars/spark-examples_2.11-2.4.3.jar \
        file:///tmp/large_sample.txt \
        file://${OUTPUT_DIR}
ENDSSH

echo "Job submission completed!"
echo "Check Master UI: http://$MASTER_IP:8080"
echo "Check Job UI: http://$MASTER_IP:4040 (during job execution)"