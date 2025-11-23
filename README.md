# Automation of Spark Deployment with Ansible and Terraform on Google Cloud Service 

This document explains how to deploy the Spark cluster using Terraform and Ansible.

Prerequisites
- gcloud CLI configured and authenticated
- Terraform installed (>= 0.12)
- Ansible installed (>= 2.9)
- jq installed (used by scripts)

Steps
1. Edit `terraform/variables.tf` or pass variables via environment `TF_VAR_project`, `TF_VAR_ssh_username`, etc.
2. Ensure `TF_VAR_ssh_public_key` points to your public key (default `~/.ssh/id_rsa.pub`).
3. Run deployment (this will apply infrastructure, configure nodes, upload data to storage and perform WordCount task):

```bash
./scripts/deploy.sh
```

