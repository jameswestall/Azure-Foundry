provider "azuredevops" {
  version               = ">= 0.0.1"
  org_service_url       = var.org_service_url
  personal_access_token = var.personal_access_token
}

provider "azuread" {
  version         = "~> 0.7.0"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

terraform {
  backend "azurerm" {}
}