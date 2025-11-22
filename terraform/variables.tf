variable "project" {
  description = "GCP project id"
  type        = string
  
  validation {
    condition     = length(var.project) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "spark-vpc"
}

variable "worker_count" {
  description = "Number of Spark worker instances"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Compute machine type"
  type        = string
  default     = "e2-medium"
}

variable "ssh_username" {
  description = "SSH username to inject into instances"
  type        = string
  default     = "sparkuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key to upload to instances"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "image_family" {
  description = "Image family to use for instances"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "spark_version" {
  description = "Spark version to install"
  type        = string
  default     = "2.4.3"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "admin_ip" {
  description = "Your current public IP for firewall access"
  type        = string
  default     = "0.0.0.0/0"  # Will be overridden
}
