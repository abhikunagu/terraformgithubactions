############################################################
# main.tf
# Multi-cloud Terraform (AWS + Azure) — explicit Azure SP auth
# IMPORTANT: do NOT commit real secrets. Set ARM_* env vars or
# TF_VAR_azure_client_id / TF_VAR_azure_client_secret in CI.
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
}

####################
# Providers
####################

provider "aws" {
  region = var.aws_region
}

# Azure provider: explicit tenant & subscription to avoid CLI fallback
provider "azurerm" {
  features {}

  # hard-coded tenant + subscription (use your tenant/sub as requested)
  tenant_id       = "314254ef-57e5-4f12-8f67-1c309bc2394b"
  subscription_id = "7ea4c47b-7d40-49d8-9496-4b52fef02f7d"

  # Prefer explicit SP credentials (set them via environment variables
  # or via TF variables for CI). If these are left empty, provider will
  # attempt other auth methods (including az cli).
  client_id     = var.azure_client_id != "" ? var.azure_client_id : null
  client_secret = var.azure_client_secret != "" ? var.azure_client_secret : null
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
    Name        = "DEVOPS"
    Environment = "Dev"
  }
}

resource "aws_ecr_repository" "devops_ecr" {
  name                 = "devops-ecr-repo1"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "DevOps"
  }
}

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

resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops-subnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

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
# Variables
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

# Azure SP auth variables (prefer setting via environment variables in CI)
variable "azure_client_id" {
  description = "Azure Service Principal client id (APP ID). Prefer setting ARM_CLIENT_ID env var instead."
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal client secret. Prefer setting ARM_CLIENT_SECRET env var instead."
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
  description = "Admin password for Azure VM. For demo only — use Key Vault in production."
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
# Outputs
####################

output "aws_instance_public_ids" {
  value       = aws_instance.devops_server[*].id
  description = "IDs of aws instances created"
}

output "azure_resource_group" {
  value       = azurerm_resource_group.devops_rg.name
  description = "Azure resource group created"
}
