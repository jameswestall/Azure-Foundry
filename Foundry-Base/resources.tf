module "Foundry-DevOps-Central-Project" {
  source               = "./Modules/Foundry-Azure-DevOps-Project"
  azure_devops_project = var.azure_foundry_base
}


resource "azuredevops_variable_group" "variablegroup" {
  project_id   = module.Foundry-DevOps-Central-Project.id
  name         = "Azure-Foundry-Variable-Group"
  description  = "Contains Secrets relevant to Azure Foundry operations"
  allow_access = true

  variable {
    name         = "backend_storage_account_name"
    value = var.backend_storage_account_name
  }

  variable {
    name         = "backend_container_name"
    value = var.backend_container_name
  }

  variable {
    name         = "foundry_project_backend_key"
    value = var.foundry_project_backend_key
  }

  variable {
    name         = "foundry_mgmt_backend_key"
    value = var.foundry_mgmt_backend_key
  }

  variable {
    name         = "ARM_CLIENT_ID"
    secret_value = var.client_id
    is_secret    = true
  }

  variable {
    name         = "ARM_SUBSCRIPTION_ID"
    secret_value = var.subscription_id
    is_secret    = true
  }

  variable {
    name         = "ARM_TENANT_ID"
    secret_value = var.tenant_id
    is_secret    = true
  }

  variable {
    name         = "ARM_CLIENT_SECRET"
    secret_value = var.client_secret
    is_secret    = true
  }

  variable {
    name         = "ARM_ACCESS_KEY"
    secret_value = var.backend_storage_account_key
    is_secret    = true
  }

  variable {
    name         = "AZDO_ORG_SERVICE_URL"
    secret_value = var.org_service_url
    is_secret    = true
  }

  variable {
    name         = "AZDO_PERSONAL_ACCESS_TOKEN"
    secret_value = var.personal_access_token
    is_secret    = true
  }
}

module "Foundry-DevOps-Projects" {
  source               = "./Modules/Foundry-Azure-DevOps-Project"
  for_each             = var.foundry_project_list
  azure_devops_project = each.value
}

module "Foundry-Azure-Core" {
  source          = "./Modules/Foundry-Azure-Core"
  subscription_id = var.azure_foundry_base.subscription_id
  customerName    = var.customerName
  deployRegion    = var.deployRegion
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#Declare a block for each area - see issues for lack of looped deployment
module "Foundry-Project-Areas-Project1" {
  source               = "./Modules/Foundry-Azure-Spoke"
  core_subscription_id = var.azure_foundry_base.subscription_id
  deployRegion         = var.deployRegion
  client_id            = var.client_id
  client_secret        = var.client_secret
  tenant_id            = var.tenant_id
  core_network_id      = module.Foundry-Azure-Core.core_network_id
  core_network_fw_ip   = module.Foundry-Azure-Core.core_network_fw_ip
  core_network_name    = module.Foundry-Azure-Core.core_network_name
  core_network_rg_name = module.Foundry-Azure-Core.core_network_rg_name
  core_network_fw_public_ip = module.Foundry-Azure-Core.core_network_fw_public_ip
  #When Copy-Pasting this module declaration, only the following variables require updates, provided that each project is correctly defined. 
  project_object  = var.foundry_project_list["project1"]
  subscription_id = var.foundry_project_list["project1"].subscription_id
  project_id      = module.Foundry-DevOps-Projects["project1"].id
}