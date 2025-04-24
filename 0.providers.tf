terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 3.116.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-backend"
    storage_account_name = "sabackendgithubmeetup"
    container_name       = "backendtf"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "174655ab-4346-4b1d-90fb-2dfdeb60e5e8"
  tenant_id       = "5a6b2fb4-b7e6-4d8c-9d10-7301abf0dbcb"
}