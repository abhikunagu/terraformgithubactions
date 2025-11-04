############################################################
# main.tf
# Combined AWS + Azure example. Use environment variables
# (ARM_*/AZURE_*) or terraform variables (TF_VAR_*) in CI.
#
# Recommended for CI:
# - Create an Azure service principal and set ARM_CLIENT_ID,
#   ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# - Or use the azure/login GitHub Action with AZURE_CREDENTIALS
############################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.47.0"
    }
  }

  # Optional: lock to a specific Terraform version if you want
  # required_version = ">= 1.4.0"
}

####################
# Providers
####################

provider "aws" {
  region = var.aws_region
}

# Azure provider:
# - Will use explicit variables if provided, otherwise provider
#   will fall back to the default Azure auth chain (env vars, managed identity, CLI).
provider "azurerm" {
  features {}

  tenant_id       = var.azure_tenant_id != "" ? var.azure_tenant_id : null
  subscription_id = var.azure_subscription_id != "" ? var.azure_subscription_id : null
  client_id       = var.azure_client_id != "" ? var.azure_client_id : null
  client_secret   = var.azure_client_secret != "" ? var.azure_client_secret : null
}

####################
# AWS Resources
####################

resource "aws_vpc" "this" {
  cidr_block = "10.31.0.0/16"

  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_instance" "devops_server" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  count         = 1

  tags = {
    Name = "DEVOPS"
    Environment = "Dev"
  }
}

# AWS ECR Repository
resource "aws_ecr_repository" "devops_ecr" {
  name                 = "devops-ecr-repo1"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "DevOps"
  }
}

# AWS S3 Bucket
resource "aws_s3_bucket" "devuserbucket" {
  bucket = var.aws_s3_bucket_name

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

####################
# Azure Resources
####################

resource "azurerm_resource_group" "devops_rg" {
  name     = "rg-terraform-demo2"
  location = var.azure_location

  tags = {
    Environment = "DevOps"
  }
}

resource "azurerm_virtual_network" "devops_vnet" {
  name                = "devops-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  tags = {
    Environment = "DevOps"
  }
}

# Subnet
resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops-subnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Network Interface (private IP only)
resource "azurerm_network_interface" "devops_nic" {
  name                = "devops-nic"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "DevOps"
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = "devops-vm"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = false
  admin_password      = var.azure_vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.devops_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    Name = "DEVOPS-VM"
  }
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "devops_acr" {
  name                = var.azure_acr_name
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = "DevOps"
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "devops_sa" {
  name                     = var.azure_storage_account_name
  resource_group_name      = azurerm_resource_group.devops_rg.name
  location                 = azurerm_resource_group.devops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "DevOps"
  }
}

####################
# Variables (can be set via TF_VAR_* or environment-backed workspace variables)
####################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_ami" {
  description = "AMI to use for aws_instance (change as required)"
  type        = string
  default     = "ami-04b4f1a9cf54c11d0"
}

variable "aws_instance_type" {
  description = "AWS instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_s3_bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
  default     = "my-tf-test-bucketnewone1"
}

# Azure auth variables (optional — prefer env vars in CI)
variable "azure_tenant_id" {
  description = "Azure Tenant ID (GUID). Prefer to provide via ARM_TENANT_ID in CI."
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID. Prefer to provide via ARM_SUBSCRIPTION_ID in CI."
  type        = string
  default     = ""
}

variable "azure_client_id" {
  description = "Azure Service Principal client id (APP ID). Prefer ARM_CLIENT_ID in CI."
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal client secret. Prefer ARM_CLIENT_SECRET in CI."
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "azure_vm_admin_password" {
  description = "Admin password for Azure VM. For demo only — use Key Vault in prod."
  type        = string
  default     = "P@ssword123!"
  sensitive   = true
}

variable "azure_acr_name" {
  description = "Azure Container Registry name (must be globally unique)"
  type        = string
  default     = "devopsacr123456"
}

variable "azure_storage_account_name" {
  description = "Azure storage account name (must be globally unique, 3-24 lowercase letters and numbers)"
  type        = string
  default     = "devopsstorage123456"
}

####################
# Outputs (optional)
####################
output "aws_instance_public_ids" {
  value       = aws_instance.devops_server[*].id
  description = "IDs of aws instances created"
}

output "azure_resource_group" {
  value       = azurerm_resource_group.devops_rg.name
  description = "Azure resource group created"
}
