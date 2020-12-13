variable "org_service_url" {
  type = string
}

variable "personal_access_token" {
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

variable "subscription_id" {
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

//base project for all Azure Foundry resources. 
variable "azure_foundry_base" {
  type = object({
    name               = string
    areaPrefix         = string
    subscription_id    = string
    vnetRange          = string
    subnetCount        = string
    subnetExtraBits    = string
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
    name               = "Azure Foundry", //default project name
    areaPrefix         = "FOUNDRY-CORE"
    subscription_id    = "10737489-ac39-415a-bd96-e76f05732c85"
    description        = "Azure Foundry allows organisations to adopt Azure & Azure DevOps at speed" // change as required
    visibility         = "private",
    vnetRange          = "10.0.0.1/20", // range to be used for core
    subnetCount        = "8",           //how many subnets to generate. 
    subnetExtraBits    = "4",           //how many bits to add to the CIDR of the parent. 1 with /23 would be /24                                                                  //private or public - suggest private for THIS repo
    version_control    = "git"          // git or tfvc 
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
  type = map(object({
    name               = string
    areaPrefix         = string
    subscription_id    = string
    vnetRange          = string
    subnetCount        = string
    subnetExtraBits    = string
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
    extraResourceGroups = map(
      object({
        name = string
        tags = map(string)
      })
    )
  }))
  default = {
    project1 = {
      name               = "Azure Foundry - Landing Project 1 ",                                     //default project name
      areaPrefix         = "Project1",                                                               //Resource Group Name will be prepended with this name
      subscription_id    = "9ddbb73f-7a81-4d90-b96a-ae360b43e1d8",                                   //subscription marked for usage
      vnetRange          = "192.168.0.0/22",                                                         // range to be used for spoke
      subnetCount        = "2",                                                                      //how many subnets to generate. 
      subnetExtraBits    = "2",                                                                      //how many bits to add to the CIDR of the parent. 1 with /23 would be /24
      description        = "This is the first project scace deployed using the Azure Cloud foundry", // change as required
      visibility         = "private",                                                                //private or public - suggest private for  repo
      version_control    = "git"                                                                     // git or tfvc 
      work_item_template = "Agile"
      repolist           = ["Azure-Cloud-Projects1"]
      features = {
        boards       = "enabled" //optional
        repositories = "enabled" //required enabled for this codebase to work
        pipelines    = "enabled" //required enabled for this codebase to work
        testplans    = "enabled" //optional
        artifacts    = "enabled" //optional
      }
      extraResourceGroups = {
        testingRG = {
          name = "TESTING-RG01"
          tags = { "Service" = "Demonstration Capability" }
        }
      }
    }
  }
}