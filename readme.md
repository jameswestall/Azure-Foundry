# Azure Foundry
The Azure Foundry is an extension of the Azure Cloud Adoption framework. 
Intended to get organizations started on Azure & Azure DevOps a using Infrastructure as Code as a driving principal, this tool initially deploys the following resources;

- Imperative Deployment
  - A resource group: "CONTOSO-AF-STATE-RG"
  - A storage account: "contosoafstate"
  - A storage account container: "azurefoundrystate"
  - Two resource locks: "azure-foundry-rg-lock" & "azure-foundry-storage-lock"
  - A Service Principal for usage within the core Azure Foundry Build pipeline (Owner - Tenant Root Group).

- Declarative Deployment
  - Azure Foundry DevOps Project
    - Initial Repository
    - Azure Pipeline
    - Service Principal Connection
    - Branch Policy
  - Azure Management Group
  - Azure Policy
  - Azure Resource Groups
  - Azure Virtual Networks
  - Azure Backup Vault & Policy
  - Azure Network Security

## Initial Usage

> . ./foundry.sh -t "00000000-0000-0000-0000-000000000000" -s "00000000-0000-0000-0000-000000000000"  -o "Contoso" -d "australiasoutheast" -a "https://dev.azure.com/foundryorg" -p "supersecretrandompersonalaccesstoken" -u "johnsmith@contoso.com"

#### Argument Reference  
d = Initial deployment region  
t = Azure AD Tenant ID  
s = Subscription ID for initial deployment  
o = Organization Name to be used throughout the deployment  

## Ongoing Usage (Future Capability)
Post execution of the initialization script, Organizations can begin to expand on their Azure deployment, using the Azure Foundry. Create a pull request against the Azure Foundry with a NEW subscription & project. 
Hopefully will replicate something like this: https://github.com/Azure/Enterprise-Scale/blob/main/docs/reference/adventureworks/README.md

