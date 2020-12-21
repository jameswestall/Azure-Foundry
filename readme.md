# Azure Foundry
The Azure Foundry is an extension of the Azure Cloud Adoption framework. 
Intended to get organizations started on Azure & Azure DevOps a using Infrastructure as Code as a driving principal, this tool initially deploys the following resources;

- Imperative Deployment
  - A resource group: "CONTOSO-AF-STATE-RG"
  - A storage account: "contosoafstate"
  - A storage account container: "azurefoundrystate"
  - Two resource locks: "azure-foundry-rg-lock" & "azure-foundry-storage-lock"
  - A Service Principal for usage within the core Azure Foundry Build pipelines (Owner - Tenant Root Group, Owned Application Admin, Directory Read-Write and User Administrator).

- Declarative Deployments
  - Azure Foundry DevOps Project
    - Initial Repository
    - Service Principal Connection
    - Branch Policy
  - Azure Management Group
  - Azure Policy
  - Azure Resource Groups
  - Azure Virtual Networks
  - Azure Backup Vault & Policy
  - Azure Network Security (NSG & Firewalls)
  - Azure IAM Assignments

## Initial Usage

> . ./foundry.sh -o "Contoso" -t "00000000-0000-0000-0000-000000000000" -s "00000000-0000-0000-0000-000000000000"   -d "australiasoutheast" -a "https://dev.azure.com/foundryorg" -p "supersecretrandompersonalaccesstoken" -u "johnsmith@contoso.com"

#### Argument Reference  
o = Organization Name to be used throughout the deployment
t = Azure AD Tenant ID  
s = Subscription ID for initial deployment  
d = Initial deployment region   
a = Azure DevOps URL for your organisation
u = Azure DevOps User account for PAT (Ideally a service account)
p = Azure DevOps Personal Access Token

## Ongoing Usage
Post execution of the initialization script, Organizations can begin to expand on their Azure deployment, using the Azure Foundry. Create a pull request against the Azure Foundry with a project within Azure DevOps, and declare an instance of the Foundry-Azure-Spoke using your project configuration. 

# Other Projects like this
The Azure Foundry design is loosely aligned with the Azure Cloud Adoption Framework. This is implemented in Terraform here.