variable "subscription_id" {
  type = string
}

variable "core_subscription_id" {
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

variable "core_network_id" {
  type = string
}

variable "core_network_fw_ip" {
  type = string
}

variable "project_id" {
  type = string
}

variable "project_object" {
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
}

variable "deployRegion" {
  type    = string
  default = "australiasoutheast"
}

variable "azureResourceGroups" {
  type = map(object({
    name = string
    tags = object({ Service = string })
    }
  ))
  default = {
    networkRG = {
      name = "NETWORK-RG01"
      tags = { "Service" = "Azure Networking" }
    }
    serverRG = {
      name = "SERVER-RG01"
      tags = { Service = "Azure Compute" }
    }
    monitoringRG = {
      name = "MONITORING-RG01"
      tags = { Service = "Azure Monitoring" }
    }
    backupRG = {
      name = "BACKUP-RG01"
      tags = { Service = "Azure Backup" }
    }
    keyvaultRG = {
      name = "KEYVAULT-RG01"
      tags = { Service = "Azure Security" }
    }
    cloudShellRG = {
      name = "CLOUDSHELL-RG01"
      tags = { Service = "Azure Management" }
    }
  }
}

variable "vnetSuffix" {
  type    = string
  default = "SPOKE-VNET"
}

variable "basetags" {
  type = map
  default = {
    createdBy      = "Azure Foundry"
    Environment    = "Production"
    BillingCode    = "1234"
    ExpiryDate     = "Never"
    CreationTicket = "1234"
    Owner          = "Contoso"
  }
}

variable "keyVaultName" {
  type    = string
  default = "KV"
}

variable "backupVaultName" {
  type    = string
  default = "BKV"
}

variable "analyticsName" {
  type    = string
  default = "ANALYTICS"
}