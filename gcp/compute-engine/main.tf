# GCP Compute Engine Module

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# VPC Subnet
resource "google_compute_subnetwork" "main" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall Rules - Allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.instance_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidr_blocks

  target_tags = [var.instance_name]
}

# Firewall Rules - Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.instance_name}-allow-http-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.instance_name]
}

# Compute Instance
resource "google_compute_instance" "main" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.self_link

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  service_account {
    email  = var.service_account_email != "" ? var.service_account_email : null
    scopes = var.scopes
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  tags = [var.instance_name]

  depends_on = [
    google_compute_firewall.allow_ssh,
    google_compute_firewall.allow_http_https
  ]
}

# Static IP Address
resource "google_compute_address" "static_ip" {
  name   = "${var.instance_name}-static-ip"
  region = var.gcp_region
}
