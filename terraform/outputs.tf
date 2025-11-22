output "ansible_inventory_path" {
  value       = local_file.ansible_inventory.filename
  description = "Path to generated Ansible inventory file"
}

output "cluster_info" {
  value = {
    master = {
      name       = google_compute_instance.master.name
      public_ip  = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
      private_ip = google_compute_instance.master.network_interface[0].network_ip
    }
    workers = [
      for worker in google_compute_instance.workers : {
        name       = worker.name
        public_ip  = worker.network_interface[0].access_config[0].nat_ip
        private_ip = worker.network_interface[0].network_ip
      }
    ]
    edge = {
      name       = google_compute_instance.edge.name
      public_ip  = google_compute_instance.edge.network_interface[0].access_config[0].nat_ip
      private_ip = google_compute_instance.edge.network_interface[0].network_ip
    }
  }
  description = "Complete cluster information"
}

# Individual outputs for easier access in scripts
output "master_ip" {
  value       = google_compute_instance.master.network_interface[0].network_ip
  description = "Master node private IP address"
}

output "master_public_ip" {
  value       = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
  description = "Master node public IP address"
}

output "worker_ips" {
  value       = [for worker in google_compute_instance.workers : worker.network_interface[0].network_ip]
  description = "Worker nodes private IP addresses"
}

output "worker_public_ips" {
  value       = [for worker in google_compute_instance.workers : worker.network_interface[0].access_config[0].nat_ip]
  description = "Worker nodes public IP addresses"
}

output "edge_ip" {
  value       = google_compute_instance.edge.network_interface[0].network_ip
  description = "Edge node private IP address"
}

output "edge_public_ip" {
  value       = google_compute_instance.edge.network_interface[0].access_config[0].nat_ip
  description = "Edge node public IP address"
}

output "gcs_bucket" {
  value       = google_storage_bucket.spark_data.name
  description = "GCS bucket name for Spark data"
}

output "gcs_bucket_url" {
  value       = "gs://${google_storage_bucket.spark_data.name}"
  description = "GCS bucket URL for Spark data"
}
