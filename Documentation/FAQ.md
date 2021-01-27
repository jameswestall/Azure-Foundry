## Frequently Asked Questions

### What is the goal of this project?
The goal of this project is to accelerate adoption of Azure, Azure DevOps and Terraform. 
As a solution, this project does it's best to align with the Azure CAF. When adopting IaC tooling, often the biggest challenge is the learning & up skill required. 
As such, this project aims to sit somewhere between the Azure CAF terraform modules and custom modules. Smaller organizations looking to accelerate within Azure should find this tool useful. 

### Can this project be better? Where can we improve it?
There is definitely areas within this codebase that can be improved. 
Improvements are welcome to the Bash scripting, documentation and Terraform Modules.

### How can I contribute to this project?
Please feel free to fork this project and raise Pull requests as required. When raising pull requests, please clearly articulate what problem you are solving and the rationale behind these updates. 

### How do I raise an issue with this project?
When raising issues with the codebase of this project please include the lines of code you suspect are causing the issue, in addition to reproduction steps. 

### Why should I use this over the Azure CAF Modules?
In honesty, you can quite happily use either with not too much effort. Development of this solution started just before Microsoft released the CAF modules & Rover. 
As a differentiator, this project currently deploys connected Azure DevOps projects to your organization. 

### Isn't there a risk that users may break other projects when using this tool?
Yes. This tooling focuses on the enablement of a centralized platform team. As secondary development/operations teams raise pull requests, it is important that this core group completes detailed reviews of each PR and calls out any major issues. At the end of the day, automated tooling only goes so far.

### Why do you use coarse grained authorization rather than fine grained?
Detailed IAM planning is often a detailed and requirements heavy process. The IAM deployments currently included with this project are aimed at driving adoption.
If you believe there is a better IAM assignment that is general enough for public consumption, please feel free to raise a PR. 

### Why don't you use services like terragrunt for multi-subscription provisioning?
Terragrunt was considered when developing this solution. At the end of the day, it was decided that adding another tool to the solution would increase complexity for not much gain. 
Issues are open for problems that Terragrunt solves, however, these will likely be fixed before a 1.0 release of Terraform.

### Why do you deploy an Azure Firewall?
Why Not? As an "Azure Native" focused solution, using an Azure Firewall was a no-brainer. While multiple IaaS options are available from vendors, this assumes a networking resource is available to maintain the solution. 
Azure Firewall provides an excellent PaaS solution, with minimal learning required by cloud engineers to adopt. 
