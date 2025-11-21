provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc" {
  name = var.network_name
}

resource "google_compute_firewall" "allow_ssh_spark" {
  name    = "allow-ssh-spark"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "8081", "4040", "7077"]
  }

  source_ranges = [var.admin_ip]
  target_tags   = ["spark"]
}

# Add internal cluster communication
resource "google_compute_firewall" "allow_internal" {
  name    = "spark-allow-internal"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_tags = ["spark"]
  target_tags = ["spark"]
}

resource "google_compute_instance" "master" {
  name         = "spark-master"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["spark", "master"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/${var.image_family}"
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  service_account {
    email  = google_service_account.spark_master.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "workers" {
  count        = var.worker_count
  name         = "spark-worker-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["spark", "worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/${var.image_family}"
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  service_account {
    email  = google_service_account.spark_worker.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "edge" {
  name         = "spark-edge"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["spark", "edge"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/${var.image_family}"
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  service_account {
    email  = google_service_account.spark_edge.email
    scopes = ["cloud-platform"]
  }
}

# Add this resource to generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_ip         = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
    master_private_ip = google_compute_instance.master.network_interface[0].network_ip
    workers          = google_compute_instance.workers
    edge_nodes       = google_compute_instance.edge
  })
  filename = "${path.module}/../ansible/inventory/hosts"
  
  depends_on = [
    google_compute_instance.master,
    google_compute_instance.workers,
    google_compute_instance.edge
  ]
}

# Generate hosts file template for all nodes
resource "local_file" "hosts_template" {
  content = templatefile("${path.module}/templates/hosts.tpl", {
    master_private_ip = google_compute_instance.master.network_interface[0].network_ip
    workers          = google_compute_instance.workers
    edge_nodes       = google_compute_instance.edge
  })
  filename = "${path.module}/../ansible/roles/spark/templates/hosts.j2"
  
  depends_on = [
    google_compute_instance.master,
    google_compute_instance.workers,
    google_compute_instance.edge
  ]
}

# Add SSH key resource (if not already present)
resource "google_compute_project_metadata_item" "ssh_keys" {
  key   = "ssh-keys"
  value = "${var.ssh_user}:${file(var.public_key_path)}"
}

resource "google_service_account" "spark_master" {
  account_id   = "spark-master-sa"
  display_name = "Spark Master Service Account"
}

resource "google_service_account" "spark_worker" {
  account_id   = "spark-worker-sa"
  display_name = "Spark Worker Service Account"
}

resource "google_service_account" "spark_edge" {
  account_id   = "spark-edge-sa"
  display_name = "Spark Edge Service Account"
}

# Grant minimal permissions
resource "google_project_iam_member" "spark_logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.spark_worker.email}"
}
