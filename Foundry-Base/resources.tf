module "Foundry-DevOps-Central-Project" {
  source               = "./Modules/Foundry-Azure-DevOps-Project"
  azure_devops_project = var.azure_foundry_base
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