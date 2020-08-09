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
  type = map
  default = {
    networkRG    = "NETWORK-RG01"
    serverRG     = "SERVER-RG01"
    monitoringRG = "MONITORING-RG01"
    backupRG     = "BACKUP-RG01"
    keyvaultRG   = "KEYVAULT-RG01"
    cloudShellRG = "CLOUDSHELL-RG01"
  }
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
    "1" = "10.1.1.0/25"
    "2" = "10.1.1.128/25"
    "3" = "10.1.2.0/25"
    "4" = "10.1.2.128/25"
  }
}

variable "azureGWSubnetRange" {
  type    = string
  default = "10.1.0.0/24"
}

variable "basetags" {
  type = map
  default = {
    createdBy          = "Azure Foundry"
    availabilityWindow = "24/7"
    environmentType    = "Production"
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