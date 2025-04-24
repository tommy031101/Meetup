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