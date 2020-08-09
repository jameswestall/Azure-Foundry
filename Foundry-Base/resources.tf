resource "azuredevops_project" "foundry-base-project" {
  project_name       = var.azure_foundry_base.name
  description        = var.azure_foundry_base.description
  visibility         = var.azure_foundry_base.visibility
  version_control    = var.azure_foundry_base.version_control
  work_item_template = var.azure_foundry_base.work_item_template
  features           = var.azure_foundry_base.features
}

resource "azuredevops_git_repository" "foundry-base-repos" {
  project_id = azuredevops_project.foundry-base-project.id
  count      = length(var.azure_foundry_base.repolist)
  name       = var.azure_foundry_base.repolist[count.index]
  initialization {
    init_type = "Uninitialized"
  }
}

resource "azuredevops_branch_policy_min_reviewers" "foundry-branch-policy" {
  count      = length(var.azure_foundry_base.repolist)
  project_id = azuredevops_project.foundry-base-project.id

  enabled  = true
  blocking = true

  settings {
    reviewer_count     = 2
    submitter_can_vote = false

    scope {
      repository_id  = azuredevops_git_repository.foundry-base-repos[count.index].id
      repository_ref = "refs/heads/master"
      match_type     = "Exact"
    }
  }
}

locals {
  foundry_project_repos = flatten([
    for index, project in var.foundry_project_list : [
      for repo in project.repolist : {
        project_index = index
        reponame  = repo
      }
    ]
  ])
}

resource "azuredevops_project" "foundry_project_list" {
  count = length(var.foundry_project_list)
  project_name       = var.foundry_project_list[count.index].name
  description        = var.foundry_project_list[count.index].description
  visibility         = var.foundry_project_list[count.index].visibility
  version_control    = var.foundry_project_list[count.index].version_control
  work_item_template = var.foundry_project_list[count.index].work_item_template
}

resource "azuredevops_git_repository" "foundry_project_list_repos" {
  count = length(local.foundry_project_repos)
  project_id = azuredevops_project.foundry_project_list[local.foundry_project_repos[count.index].project_index].id
  name       = local.foundry_project_repos[count.index].reponame
  initialization {
    init_type = "Uninitialized"
  }
}

resource "azuredevops_branch_policy_min_reviewers" "project-branch-policy" {
  count = length(local.foundry_project_repos)
  project_id = azuredevops_project.foundry_project_list[local.foundry_project_repos[count.index].project_index].id

  enabled  = true
  blocking = true

  settings {
    reviewer_count     = 2
    submitter_can_vote = false

    scope {
      repository_id  = azuredevops_git_repository.foundry_project_list_repos[count.index].id
      repository_ref = "refs/heads/master"
      match_type     = "Exact"
    }
  }
}

module "core-subscription" {
  source = "./Modules/BaseSubscription"
  customerName = var.customerName
  deployRegion = var.deployRegion
}

/*
resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "TestServiceRM"
  credentials {
    serviceprincipalid  = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"
    serviceprincipalkey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
  azurerm_spn_tenantid      = "xxxxxxx-xxxx-xxx-xxxxx-xxxxxxxx"
  azurerm_subscription_id   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"
  azurerm_subscription_name = "Sample Subscription"
} 
*/