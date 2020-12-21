# Identity and Access Management (IAM)
This solution defines a group based solution for IAM access to Azure Resources. PIM is currently not utilized, however this may change pending release of an AzureAD provider that supports MS Graph.


#### Core Assignments
The following assignments are created for the "Core" areas. Membership should be reserved for users of a central cloud platform team. 
|Group|Role|Resource Group|
|-----|----|--------------|
|admin-azure-foundry-CoreName-owner|Owner|All Resource Groups in Core Area|
|admin-azure-foundry-CoreName-contributor|Contributor|All Resource Groups in Core Area|
|admin-azure-foundry-CoreName-reader|Reader|All Resource Groups in Core Area|


#### Project Assignments
The following assignments are created for project areas. 

|Group|Role|Resource Group|
|-----|----|--------------|
|admin-azure-foundry-ProjectName-owner|Owner|All Resource Groups in Project|
|admin-azure-foundry-ProjectName-contributor|Contributor|All Resource Groups in Project|
|admin-azure-foundry-ProjectName-generaluser|Virtual Machine Contributor|Project Server Resource group|
|admin-azure-foundry-ProjectName-generaluser|Log Analytics Contributor|Project Monitoring Resource group|
|admin-azure-foundry-ProjectName-generaluser|Key Vault Contributor|Project Keyvault Resource group|
|admin-azure-foundry-ProjectName-generaluser|Network Contributor|Project Network Resource group|
|admin-azure-foundry-ProjectName-generaluser|Contributor|All "Extra" Resource groups|
|admin-azure-foundry-ProjectName-reader|Reader|All Resource Groups in Project|