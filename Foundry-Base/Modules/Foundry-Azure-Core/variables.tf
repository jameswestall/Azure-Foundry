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

variable "deployRegionTimeZone" {
  type    = string
  default = "E. Australia Standard Time"
}

variable "azureResourceGroups" {
  type = map(object({
    name = string
    tags = object({ service = string })
    }
  ))
  default = {
    networkRG = {
      name = "NETWORK-RG01"
      tags = { "service" = "Azure Networking" }
    }
    serverRG = {
      name = "SERVER-RG01"
      tags = { "service" = "Azure Compute" }
    }
    monitoringRG = {
      name = "MONITORING-RG01"
      tags = { "service" = "Azure Monitoring" }
    }
    backupRG = {
      name = "BACKUP-RG01"
      tags = { "service" = "Azure Backup" }
    }
    keyvaultRG = {
      name = "KEYVAULT-RG01"
      tags = { "service" = "Azure Security" }
    }
    cloudShellRG = {
      name = "CLOUDSHELL-RG01"
      tags = { "service" = "Azure Management" }
    }
  }
}

variable "areaPrefix" {
  type    = string
  default = "CORE"
}

variable "vnetName" {
  type    = string
  default = "CORE-VNET-01"
}

variable "vnetRanges" {
  type    = list
  default = ["10.1.0.0/16"]
}

variable "azureSubnetRanges" {
  type = map
  default = {
    "1" = "10.1.5.0/25"
    "2" = "10.1.5.128/25"
    "3" = "10.1.6.0/25"
    "4" = "10.1.6.128/25"
  }
}

variable "azureGWSubnetRange" {
  type    = string
  default = "10.1.0.0/24"
}

variable "azureFWSubnetRange" {
  type    = string
  default = "10.1.1.0/24"
}

variable "pepSubnetRange" {
  type    = string
  default = "10.1.2.0/24"
}

variable "bastionSubnetRange" {
  type    = string
  default = "10.1.3.0/24"
}

variable "wafSubnetRange" {
  type    = string
  default = "10.1.4.0/24"
}

variable "azureFWName" {
  type    = string
  default = "CORE-AZURE-FW"
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
  default = "BKV-01"
}

variable "analyticsName" {
  type    = string
  default = "ANALYTICS"
}

variable "azureAdminGroupT3" {
  type    = string
  default = "Azure Tier 3 Admin"

}

variable "azureAdminGroupT2" {
  type    = string
  default = "Azure Tier 2 Admin"
}

variable "azureAdminGroupT1" {
  type    = string
  default = "Azure Tier 1 Admin"
}