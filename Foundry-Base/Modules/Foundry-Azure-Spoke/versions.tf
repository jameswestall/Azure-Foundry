terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
    azuredevops = {
      source = "terraform-providers/azuredevops"
    }
  }
  required_version = ">= 0.13"
}
