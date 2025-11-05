terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.47.0"
    }
  }
}

################################################################
# Azure provider: explicit tenant & subscription to avoid CLI fallback
# IMPORTANT: set the SP secret (client id + client secret) before running.
################################################################

provider "azurerm" {
  features {}

  # Default tenant & subscription you asked to use (override with TF_VAR_* or ARM_* env if needed)
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id

  # Client credentials MUST be provided (via TF var or ARM_* env). This prevents az CLI fallback.
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
}

# Minimal example resource group
resource "azurerm_resource_group" "devops_rg" {
  name     = "rg-terraform-demo2"
  location = var.azure_location
}

###########################
# Variables
###########################

variable "azure_tenant_id" {
  description = "Azure Tenant ID (GUID). Default set to tenant you provided."
  type        = string
  default     = "314254ef-57e5-4f12-8f67-1c309bc2394b"
  validation {
    condition     = length(trimspace(var.azure_tenant_id)) > 0
    error_message = "azure_tenant_id must not be empty."
  }
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID. Default set to subscription you provided."
  type        = string
  default     = "7ea4c47b-7d40-49d8-9496-4b52fef02f7d"
  validation {
    condition     = length(trimspace(var.azure_subscription_id)) > 0
    error_message = "azure_subscription_id must not be empty."
  }
}

variable "azure_client_id" {
  description = "Azure Service Principal client id (APP ID). Provide via TF_VAR_azure_client_id or ARM_CLIENT_ID env var."
  type        = string
  sensitive   = true
  default     = "e8c2751a-8993-4755-a427-bc02de548374"
  validation {
    condition     = length(trimspace(var.azure_client_id)) > 0
    error_message = "azure_client_id must be provided (TF_VAR_azure_client_id or set ARM_CLIENT_ID in environment)."
  }
}

variable "azure_client_secret" {
  description = "Azure Service Principal client secret (value). Provide via TF_VAR_azure_client_secret or ARM_CLIENT_SECRET env var."
  type        = string
  sensitive   = true
  default     = "AUi8Q~fkKJoGgKiw9rHT-AKw-9u4.QbZb9gj-dnY"
  validation {
    condition     = length(trimspace(var.azure_client_secret)) > 0
    error_message = "azure_client_secret must be provided (TF_VAR_azure_client_secret or set ARM_CLIENT_SECRET in environment)."
  }
}

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}
