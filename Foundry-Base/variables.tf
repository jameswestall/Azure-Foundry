variable "org_service_url" {
  type = string
}

variable "personal_access_token" {
  type = string
}

variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "tenant_id" {
  type = string
}

variable "customerName" {
  type    = string
  default = "Company"
}

variable "deployRegion" {
  type    = string
  default = "australiasoutheast"
}

//base azure devops project for all Azure Foundry resources. 
variable "azure_foundry_base" {
  type = object({
    name               = string
    description        = string
    visibility         = string
    version_control    = string
    work_item_template = string
    repolist           = list(string)
    features = object({
      boards       = string
      repositories = string
      pipelines    = string
      testplans    = string
      artifacts    = string
    })
  })
  default = {
    name               = "Azure Foundry",                                                            //default project name
    description        = "Azure Foundry allows organisations to adopt Azure & Azure DevOps at speed" // change as required
    visibility         = "private",                                                                  //private or public - suggest private for THIS repo
    version_control    = "git"                                                                       // git or tfvc 
    work_item_template = "Agile"
    repolist           = ["Azure-Cloud-Foundry-Projects", "Azure-Cloud-Foundry-ManagementGroups", "Azure-Cloud-Foundry-Other"]
    features = {
      boards       = "enabled" //optional
      repositories = "enabled" //required enabled for this codebase to work
      pipelines    = "enabled" //required enabled for this codebase to work
      testplans    = "enabled" //optional
      artifacts    = "enabled" //optional
    }
  }
}

 //Add Azure DevOps projects here
variable "foundry_project_list" {
  type = list(object({
    name               = string
    description        = string
    visibility         = string
    version_control    = string
    work_item_template = string
    repolist           = list(string)
    features = object({
      boards       = string
      repositories = string
      pipelines    = string
      testplans    = string
      artifacts    = string
    })
  }))
  default = [
    {
    name               = "Azure Foundry - Landing Project 1 ",                                                            //default project name
    description        = "This is the first project scace deployed using the Azure Cloud foundry" // change as required
    visibility         = "private",                                                                  //private or public - suggest private for THIS repo
    version_control    = "git"                                                                       // git or tfvc 
    work_item_template = "Agile"
    repolist           = ["Azure-Cloud-Projects1"]
    features = {
      boards       = "enabled" //optional
      repositories = "enabled" //required enabled for this codebase to work
      pipelines    = "enabled" //required enabled for this codebase to work
      testplans    = "enabled" //optional
      artifacts    = "enabled" //optional
    }
  }
  ]
}