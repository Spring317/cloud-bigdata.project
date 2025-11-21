#!/usr/bin/env bash
# Wait for SSH to be ready on all instances
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Waiting for SSH to be ready on all instances..."

MASTER_IP=$(terraform -chdir=terraform output -raw master_public_ip)
WORKER_IPS=$(terraform -chdir=terraform output -json worker_public_ips | jq -r '.[]')
EDGE_IP=$(terraform -chdir=terraform output -raw edge_public_ip)

ALL_IPS="$MASTER_IP $WORKER_IPS $EDGE_IP"

for ip in $ALL_IPS; do
  echo -n "Waiting for $ip... "
  MAX_ATTEMPTS=60
  ATTEMPT=0
  
  while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes ubuntu@$ip "echo 'SSH Ready'" >/dev/null 2>&1; then
      echo "Ready"
      break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
      echo "Timeout after ${MAX_ATTEMPTS} attempts"
      exit 1
    fi
    
    sleep 5
  done
done

echo "==> All instances are ready!"
