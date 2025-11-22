 #!/usr/bin/env bash
# Deployment orchestration script (terraform + ansible)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/terraform"

echo "==> Initialize Terraform"
terraform init

echo "==> Terraform plan"
terraform plan -var "project=${TF_VAR_project:-}" -out=plan.tfplan

echo "==> Terraform apply"
terraform apply -auto-approve plan.tfplan

echo "==> Generate Ansible inventory from terraform outputs"
cd "$ROOT_DIR"
MASTER_IP=$(terraform -chdir=terraform output -raw master_ip)
MASTER_PUBLIC_IP=$(terraform -chdir=terraform output -raw master_public_ip)
WORKER_IPS=$(terraform -chdir=terraform output -json worker_ips)
WORKER_PUBLIC_IPS=$(terraform -chdir=terraform output -json worker_public_ips)
EDGE_IP=$(terraform -chdir=terraform output -raw edge_ip)
EDGE_PUBLIC_IP=$(terraform -chdir=terraform output -raw edge_public_ip)

INVENTORY_FILE=ansible/inventory.ini
cat > "$INVENTORY_FILE" <<EOF
[master]
spark-master ansible_host=${MASTER_PUBLIC_IP} private_ip=${MASTER_IP} ansible_user=ubuntu

[workers]
EOF

# append workers
WORKER_COUNT=0
echo "$WORKER_IPS" | jq -r '.[]' > /tmp/worker_private_ips.txt
echo "$WORKER_PUBLIC_IPS" | jq -r '.[]' > /tmp/worker_public_ips.txt
paste /tmp/worker_public_ips.txt /tmp/worker_private_ips.txt | while read public_ip private_ip; do
  WORKER_COUNT=$((WORKER_COUNT + 1))
  echo "spark-worker-${WORKER_COUNT} ansible_host=${public_ip} private_ip=${private_ip} ansible_user=ubuntu" >> "$INVENTORY_FILE"
done

cat >> "$INVENTORY_FILE" <<EOF

[edge]
spark-edge ansible_host=${EDGE_PUBLIC_IP} private_ip=${EDGE_IP} ansible_user=ubuntu

[spark_cluster:children]
master
workers
edge

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory written to $INVENTORY_FILE"

echo "==> Wait for SSH to be ready on all instances"
bash "$ROOT_DIR/scripts/wait-for-ssh.sh"

echo "==> Run Ansible playbook"
ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/site.yml --become

echo "Deployment finished."
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Test Google Cloud Storage access:"
echo "   bash scripts/test_gcs.sh"
echo ""
echo "2. Submit WordCount job using GCS storage:"
echo "   bash scripts/submit_wordcount_gcs.sh"
echo ""
echo "Or submit WordCount job using local files:"
echo "   bash scripts/submit_wordcount.sh"
echo ""
echo "=========================================="
echo "Web UIs:"
echo "=========================================="
echo "Spark Master:  http://${MASTER_PUBLIC_IP}:8080"
GCS_BUCKET=$(terraform -chdir=terraform output -raw gcs_bucket)
echo "GCS Bucket:    gs://${GCS_BUCKET}"
echo "GCS Console:   https://console.cloud.google.com/storage/browser/${GCS_BUCKET}"
echo "=========================================="