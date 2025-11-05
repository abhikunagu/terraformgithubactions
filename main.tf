provider "azurerm" {
  features {}
}
#
resource "azurerm_resource_group" "devops_rg" {
  name     = "rg-terraform-demo2"
  location = "East US"
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

# Network Interface
# Network Interface (private IP only)
resource "azurerm_network_interface" "devops_nic" {
  name                = "devops-nic"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id removed
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
  admin_password      = "P@ssword123!"  # ⚠️ For demo only. Use variables or Key Vault in production

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
  name                     = "devopsacr123456"   # must be globally unique
  resource_group_name      = azurerm_resource_group.devops_rg.name
  location                 = azurerm_resource_group.devops_rg.location
  sku                      = "Basic"
  admin_enabled            = true

  tags = {
    Environment = "DevOps"
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "devops_sa" {
  name                     = "devopsstorage123456"   # globally unique
  resource_group_name      = azurerm_resource_group.devops_rg.name
  location                 = azurerm_resource_group.devops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "DevOps"
  }
}
