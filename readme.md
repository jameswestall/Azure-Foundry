# Azure Foundry
The Azure Foundry is a loose implementation of the Azure Enterprise Scale Landing Zones [architecture](https://docs.microsoft.com/en-gb/azure/cloud-adoption-framework/ready/enterprise-scale/architecture#high-level-architecture). This project aims to act as an entry point for organisations who think that the [caf-terraform-landingzones](https://github.com/Azure/caf-terraform-landingzones) project is too complex, but still desire to use Terraform for both Azure & Azure DevOps. 
Using Infrastructure as Code as a driving principal, this tool initially deploys the following resources;

- Imperative Deployment
  - A resource group: "CONTOSO-AF-STATE-RG"
  - A storage account: "contosoafstate"
  - A storage account container: "azurefoundrystate"
  - Two resource locks: "azure-foundry-rg-lock" & "azure-foundry-storage-lock"
  - A **highly privileged** service principal for usage within the core Azure Foundry Build pipelines (Owner - Tenant Root Group, Owned Application Admin, Directory Read-Write and User Administrator).

- Declarative Deployments
  - Azure Foundry DevOps Project (Core)
    - Initial Repository
    - Service Principal Connection
    - Branch Policy
  - Azure Management Group(s)
  - Azure Policy
  - Core & Landing Zone deployments including,
    - Azure Resource Groups
    - Azure Virtual Networks
    - Azure Backup Vault & Policy
    - Azure Network Security (NSG, UDR & Firewalls)
    - Azure IAM Assignments
    - Service Principals per landing zone
    - Azure DevOps projects per landing zone

## Initial Usage

> . ./foundry.sh -o "Contoso" -t "00000000-0000-0000-0000-000000000000" -s "00000000-0000-0000-0000-000000000000"   -d "australiasoutheast" -a "https://dev.azure.com/foundryorg"  -u "johnsmith@contoso.com" -p "supersecretrandompersonalaccesstoken"

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
The Azure Foundry design is loosely aligned with the [Azure Cloud Adoption Framework](https://docs.microsoft.com/en-gb/azure/cloud-adoption-framework/).
There is enterprise scale templates published by Microsoft for both:
- [Azure Resource Manager (ARM)](https://github.com/Azure/Enterprise-Scale)
- [Terraform](https://github.com/Azure/caf-terraform-landingzones)