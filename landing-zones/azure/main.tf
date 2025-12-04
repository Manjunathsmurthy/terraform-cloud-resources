# Azure Landing Zone - Enterprise Foundation
# Implements Azure best practices for multi-tenant organization

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# ===== MANAGEMENT GROUPS =====
resource "azurerm_management_group" "organization" {
  display_name = var.organization
}

resource "azurerm_management_group" "production" {
  display_name       = "Production"
  parent_management_group_id = azurerm_management_group.organization.id
}

resource "azurerm_management_group" "nonproduction" {
  display_name       = "Non-Production"
  parent_management_group_id = azurerm_management_group.organization.id
}

# ===== RESOURCE GROUPS =====
resource "azurerm_resource_group" "management" {
  name     = "${var.organization}-management-rg"
  location = var.azure_region

  tags = {
    Environment = "Management"
    Purpose     = "Landing Zone Foundations"
  }
}

resource "azurerm_resource_group" "production" {
  name     = "${var.organization}-prod-rg"
  location = var.azure_region

  tags = {
    Environment = "Production"
  }
}

# ===== VIRTUAL NETWORKS =====
resource "azurerm_virtual_network" "production" {
  name                = "${var.organization}-prod-vnet"
  location            = azurerm_resource_group.production.location
  resource_group_name = azurerm_resource_group.production.name
  address_space       = var.prod_vnet_address_space

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_subnet" "production_app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.production.name
  virtual_network_name = azurerm_virtual_network.production.name
  address_prefixes     = var.prod_app_subnet_prefix
}

resource "azurerm_subnet" "production_db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.production.name
  virtual_network_name = azurerm_virtual_network.production.name
  address_prefixes     = var.prod_db_subnet_prefix
}

# ===== NETWORK SECURITY GROUPS =====
resource "azurerm_network_security_group" "production_app" {
  name                = "${var.organization}-prod-app-nsg"
  location            = azurerm_resource_group.production.location
  resource_group_name = azurerm_resource_group.production.name

  security_rule {
    name                       = "AllowHttps"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttp"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Production"
  }
}

# ===== STORAGE FOR DIAGNOSTICS =====
resource "azurerm_storage_account" "diagnostics" {
  name                     = "${var.organization}diag${data.azurerm_client_config.current.subscription_id}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  https_traffic_only_enabled = true

  tags = {
    Purpose = "Diagnostics"
  }
}

# ===== KEY VAULT FOR SECRETS =====
resource "azurerm_key_vault" "landing_zone" {
  name                = "${var.organization}-lz-kv-${data.azurerm_client_config.current.subscription_id}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90

  tags = {
    Purpose = "Landing Zone"
  }
}

# ===== MONITORING =====
resource "azurerm_log_analytics_workspace" "organization" {
  name                = "${var.organization}-law"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Purpose = "Monitoring"
  }
}

resource "azurerm_monitor_action_group" "organization" {
  name                = "${var.organization}-action-group"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = var.organization
}

# ===== ACTIVITY LOG DIAGNOSTICS =====
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name               = "${var.organization}-activity-log-diag"
  target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.organization.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }
}

# ===== POLICY ASSIGNMENT FOR COMPLIANCE =====
resource "azurerm_subscription_policy_assignment" "enforce_https" {
  name              = "enforce-https"
  subscription_id   = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/policyDefinitions/a1181c5f-672a-4630-bb64-4811aead3da8"
  enforce           = true
}

# Data sources
data "azurerm_client_config" "current" {}
