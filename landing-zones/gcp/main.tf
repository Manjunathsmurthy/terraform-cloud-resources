# GCP Landing Zone - Enterprise Foundation
# Implements GCP best practices for multi-project organization

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

# ===== ORGANIZATION SETUP =====
resource "google_folder" "organization" {
  display_name = var.organization
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "production" {
  display_name = "Production"
  parent       = google_folder.organization.name
}

resource "google_folder" "development" {
  display_name = "Development"
  parent       = google_folder.organization.name
}

resource "google_folder" "shared_services" {
  display_name = "Shared Services"
  parent       = google_folder.organization.name
}

# ===== PROJECTS =====
resource "google_project" "production" {
  name       = "${var.organization}-production"
  project_id = "${var.organization}-prod-${data.google_client_config.current.project}"
  folder_id  = google_folder.production.name

  labels = {
    environment = "production"
    owner       = var.organization
  }
}

resource "google_project" "shared_services" {
  name       = "${var.organization}-shared-services"
  project_id = "${var.organization}-shared-svc-${data.google_client_config.current.project}"
  folder_id  = google_folder.shared_services.name

  labels = {
    environment = "shared"
    owner       = var.organization
  }
}

# ===== VPC NETWORKS =====
resource "google_compute_network" "production" {
  name                    = "${var.organization}-prod-vpc"
  project                 = google_project.production.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "production" {
  name          = "${var.organization}-prod-subnet"
  ip_cidr_range = var.prod_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.production.id
  project       = google_project.production.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ===== CLOUD ARMOR SECURITY POLICIES =====
resource "google_compute_security_policy" "production" {
  name    = "${var.organization}-prod-policy"
  project = google_project.production.project_id

  # Allow all traffic by default
  rules {
    action   = "allow"
    priority = "65535"
    match {
      versioned_expr = "FIREWALL_RULES"
      expr {
        expression = "true"
      }
    }
    description = "Default allow rule"
  }
}

# ===== FIREWALL RULES =====
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.organization}-allow-internal"
  network = google_compute_network.production.name
  project = google_project.production.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.prod_subnet_cidr]
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.organization}-allow-https"
  network = google_compute_network.production.name
  project = google_project.production.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# ===== CLOUD LOGGING =====
resource "google_logging_project_bucket_config" "production" {
  project        = google_project.production.project_id
  location       = var.gcp_region
  bucket_id      = "_Default"
  retention_days = 30
}

# ===== SERVICE ACCOUNTS =====
resource "google_service_account" "infrastructure" {
  account_id   = "infrastructure"
  display_name = "Infrastructure Management"
  project      = google_project.production.project_id
}

# ===== IAM ROLES AND BINDINGS =====
resource "google_project_iam_member" "infrastructure_admin" {
  project = google_project.production.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.infrastructure.email}"
}

resource "google_project_iam_member" "infrastructure_security" {
  project = google_project.production.project_id
  role    = "roles/iam.securityAdmin"
  member  = "serviceAccount:${google_service_account.infrastructure.email}"
}

# ===== AUDIT LOGGING =====
resource "google_folder_iam_audit_config" "organization_audit" {
  folder             = google_folder.organization.name
  service            = "compute.googleapis.com"
  audit_log_configs {
    log_type = "ADMIN_WRITE"
  }
  audit_log_configs {
    log_type = "DATA_WRITE"
  }
  audit_log_configs {
    log_type = "DATA_READ"
  }
}

# ===== MONITORING AND ALERTING =====
resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.organization} Email"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
  project = google_project.production.project_id
}

resource "google_monitoring_alert_policy" "uptime" {
  display_name = "${var.organization} Uptime Check"
  combiner     = "OR"
  project      = google_project.production.project_id

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# ===== CLOUD STORAGE FOR TERRAFORM STATE =====
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.organization}-terraform-state-${data.google_client_config.current.project}"
  project       = google_project.shared_services.project_id
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = null
  }

  labels = {
    purpose = "terraform-state"
  }
}

# ===== APIS ENABLEMENT =====
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "storage-api.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudasset.googleapis.com"
  ])

  project = google_project.production.project_id
  service = each.value
}

# Data sources
data "google_client_config" "current" {}
