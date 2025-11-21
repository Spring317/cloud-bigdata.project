# GCP Project Configuration
project = "spark-automation-1763590375"

# Region and Zone
region = "us-central1"
zone   = "us-central1-a"

# Network Configuration
network_name = "spark-vpc"

# Compute Configuration
worker_count  = 2
machine_type  = "e2-medium"

# SSH Configuration
ssh_user = "ubuntu"
public_key_path = "~/.ssh/id_rsa.pub"

# Image Configuration
image_family = "ubuntu-2204-lts"

# Spark Configuration
spark_version = "2.4.3"