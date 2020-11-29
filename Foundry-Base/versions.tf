terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azuredevops = {
      source = "terraform-providers/azuredevops"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
