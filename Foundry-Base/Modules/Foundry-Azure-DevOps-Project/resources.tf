resource "azuredevops_project" "azure_devops_project" {
  name               = var.azure_devops_project.name
  description        = var.azure_devops_project.description
  visibility         = var.azure_devops_project.visibility
  version_control    = var.azure_devops_project.version_control
  work_item_template = var.azure_devops_project.work_item_template
  features           = var.azure_devops_project.features
  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "azuredevops_git_repository" "azure_devops_project_repos" {
  project_id = azuredevops_project.azure_devops_project.id
  count      = length(var.azure_devops_project.repolist)
  name       = var.azure_devops_project.repolist[count.index]
  initialization {
    init_type = "Uninitialized"
  }
}

resource "azuredevops_branch_policy_min_reviewers" "azure_devops_project_branchpolicy" {
  count      = length(var.azure_devops_project.repolist)
  project_id = azuredevops_project.azure_devops_project.id

  enabled  = true
  blocking = true

  settings {
    reviewer_count     = 2
    submitter_can_vote = false

    scope {
      repository_id  = azuredevops_git_repository.azure_devops_project_repos[count.index].id
      repository_ref = "refs/heads/master"
      match_type     = "Exact"
    }
  }
}