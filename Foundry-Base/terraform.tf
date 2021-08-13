terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
  backend "azurerm" {}
}
