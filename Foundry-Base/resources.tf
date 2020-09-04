# resource "azuredevops_project" "foundry-base-project" {
#   project_name       = var.azure_foundry_base.name
#   description        = var.azure_foundry_base.description
#   visibility         = var.azure_foundry_base.visibility
#   version_control    = var.azure_foundry_base.version_control
#   work_item_template = var.azure_foundry_base.work_item_template
#   features           = var.azure_foundry_base.features
# }

# resource "azuredevops_git_repository" "foundry-base-repos" {
#   project_id = azuredevops_project.foundry-base-project.id
#   count      = length(var.azure_foundry_base.repolist)
#   name       = var.azure_foundry_base.repolist[count.index]
#   initialization {
#     init_type = "Uninitialized"
#   }
# }

# resource "azuredevops_branch_policy_min_reviewers" "foundry-branch-policy" {
#   count      = length(var.azure_foundry_base.repolist)
#   project_id = azuredevops_project.foundry-base-project.id

#   enabled  = true
#   blocking = true

#   settings {
#     reviewer_count     = 2
#     submitter_can_vote = false

#     scope {
#       repository_id  = azuredevops_git_repository.foundry-base-repos[count.index].id
#       repository_ref = "refs/heads/master"
#       match_type     = "Exact"
#     }
#   }
# }

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
  #When Copy-Pasting this module declaration, only the following variables require updates. 
  project_object       = var.foundry_project_list["project1"]
  subscription_id      = var.foundry_project_list["project1"].subscription_id
  project_id           = module.Foundry-DevOps-Projects["project1"].id
}