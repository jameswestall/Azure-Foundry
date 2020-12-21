# Adding a Project

### What is a Project?
This solution uses "Project" as a term to define both an Azure deployment and an Azure DevOps project.
The Azure deployment includes a base set of resources, such as a log analytics workspace, networking, KeyVault. 
The Azure DevOps deployment includes a project, repos, pipelines and a branch policy. 

### Adding a Project
Adding a project should be a simple task.

Pre-Step: If required, engage a cloud platform group to create a new subscription
1. Create a branch of the "Azure-Foundry" project
2. Update the variables file with appropriate JSON for your project
3. Raise a PR for the cloud engineering team to approve. The following checks are important
    - Not modifying core modules without an understanding of the impact to other teams
    - Not overlapping with a peered network
    - Network ranges are acceptable

4. Once approved, the cloud team can execute the the Azure devops pipelines with updates to the global deployment. 