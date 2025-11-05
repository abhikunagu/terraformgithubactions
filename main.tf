terraform {
 required_providers {
   azurerm = {
       source  = "hashicorp/azurerm"
       version = "4.47.0"   # pick latest stable

    }
  }
}

##############################################################################################
provider "azurerm" {
  features {}
}
#
resource "azurerm_resource_group" "devops_rg" {
  name     = "rg-terraform-demo2"
  location = "East US"
}



