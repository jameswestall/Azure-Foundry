output "ssh_url_projects" {
  value = azuredevops_git_repository.foundry-base-repos[0].ssh_url
}

output "ssh_url_mgmt" {
    value = azuredevops_git_repository.foundry-base-repos[1].ssh_url
}

output "foundry_project_repos" {
    value = local.foundry_project_repos
}