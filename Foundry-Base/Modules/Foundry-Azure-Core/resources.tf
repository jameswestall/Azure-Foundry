provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_string" "random" {
  length  = 10
  upper   = false
  number  = false
  special = false
}

resource "azurerm_resource_group" "azureResourceGroups" {
  name     = upper("${var.areaPrefix}-${element(values(var.azureResourceGroups), count.index).name}")
  count    = length(var.azureResourceGroups)
  location = var.deployRegion
  tags     = merge(var.basetags, element(values(var.azureResourceGroups), count.index).tags, { "location" = "${var.deployRegion}" })
}

resource "azurerm_virtual_network" "azureVnet" {
  name                = var.vnetName
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  location            = var.deployRegion
  address_space       = var.vnetRanges
  depends_on          = [azurerm_resource_group.azureResourceGroups]
  tags                = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
}

resource "azurerm_network_watcher" "azureNetworkWatcher" {
  name                = "${var.deployRegion}-networkwatcher"
  location            = var.deployRegion
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_network_security_group" "azureVnetNsgs" {
  name                = format("CORE-VNET-NSG-SUB%02s", count.index + 1)
  location            = var.deployRegion
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  count               = length(var.azureSubnetRanges)
  tags                = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_route_table" "azureVnetRoutes" {
  count                         = length(var.azureSubnetRanges)
  name                          = format("CORE-VNET-RTBL-SUB%02s", count.index + 1)
  location                      = var.deployRegion
  resource_group_name           = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  disable_bgp_route_propagation = false
  tags                          = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on                    = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_subnet" "azureVnetSubnets" {
  name                 = format("CORE-VNET-PROD-SUB%02s", count.index + 1)
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${element(values(var.azureSubnetRanges), count.index)}"]
  count                = length(var.azureSubnetRanges)
  depends_on           = [azurerm_virtual_network.azureVnet]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet_route_table_association" "azureVnetRoutesAssociation" {
  count          = length(var.azureSubnetRanges)
  subnet_id      = azurerm_subnet.azureVnetSubnets[count.index].id
  route_table_id = azurerm_route_table.azureVnetRoutes[count.index].id
}

resource "azurerm_subnet_network_security_group_association" "azureVnetNsgAssociation" {
  count                     = length(var.azureSubnetRanges)
  subnet_id                 = azurerm_subnet.azureVnetSubnets[count.index].id
  network_security_group_id = azurerm_network_security_group.azureVnetNsgs[count.index].id
}

resource "azurerm_subnet" "azureVnetGatewaySN" {
  name                 = "GatewaySubnet"
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${var.azureGWSubnetRange}"]
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_subnet" "azureVnetPrivateEndpointSN" {
  name                 = "PrivateEndpointSubnet"
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${var.pepSubnetRange}"]
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_subnet" "azureVnetFirewallSN" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${var.azureFWSubnetRange}"]
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_subnet" "azureVnetBastionSN" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${var.bastionSubnetRange}"]
  depends_on           = [azurerm_virtual_network.azureVnet]
}


resource "azurerm_network_security_group" "azureVnetBastionNSG" {
  name                = "CORE-VNET-NSG-AzureBastionSubnet"
  location            = var.deployRegion
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  tags                = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_subnet_network_security_group_association" "azureVnetBastionNSGAssociation" {
  subnet_id                 = azurerm_subnet.azureVnetBastionSN.id
  network_security_group_id = azurerm_network_security_group.azureVnetBastionNSG.id
}

resource "azurerm_subnet" "azureVnetWAFSN" {
  name                 = "AzureApplicationGatewaySubnet"
  resource_group_name  = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = var.vnetName
  address_prefixes     = ["${var.wafSubnetRange}"]
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_public_ip" "azureVnetFirewallIP" {
  name                = upper("${var.azureFWName}-IP")
  location            = var.deployRegion
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_firewall" "azureFirewall" {
  name                = var.azureFWName
  location            = var.deployRegion
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azureVnetFirewallSN.id
    public_ip_address_id = azurerm_public_ip.azureVnetFirewallIP.id
  }
}

#Create a Azure Firewall Network Rule for Google, Cloudflare & Quad9 DNS
resource "azurerm_firewall_network_rule_collection" "azureFirewall-dns" {
  name                = "azure-firewall-dns-rule"
  azure_firewall_name = azurerm_firewall.azureFirewall.name
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "Allow-DNS"
    source_addresses      = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
    destination_ports     = ["53"]
    destination_addresses = ["8.8.8.8", "8.8.4.4", "9.9.9.9", "1.1.1.1", "1.0.0.1"]
    protocols             = ["TCP", "UDP"]
  }
}

#Create a Azure Firewall Network Rule for Azure Active Directoy
resource "azurerm_firewall_network_rule_collection" "azureFirewall-aad" {
  name                = "azure-firewall-azure-ad-rule"
  azure_firewall_name = azurerm_firewall.azureFirewall.name
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  priority            = 104
  action              = "Allow"
  rule {
    name                  = "Allow-AzureAD"
    source_addresses      = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
    destination_ports     = ["25"]
    destination_addresses = ["AzureActiveDirectory"]
    protocols             = ["TCP", "UDP"]
  }
}

# Create a Azure Firewall Application Rule for Windows Update
resource "azurerm_firewall_application_rule_collection" "azureFirewall-windowsupdate" {
  name                = "azure-firewall-windows-update-rule"
  azure_firewall_name = azurerm_firewall.azureFirewall.name
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  priority            = 1000
  action              = "Allow"
  rule {
    name             = "Allow-WindowsUpdate"
    source_addresses = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
    fqdn_tags        = ["WindowsUpdate"]
  }
}

resource "azurerm_storage_account" "azureCloudShellAccount" {
  name                     = "cloudshell${random_string.random.result}"
  resource_group_name      = upper("${var.areaPrefix}-${var.azureResourceGroups["cloudShellRG"].name}")
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = merge(var.basetags, { "Service" = "Azure Management", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_storage_share" "azureCloudShellShare" {
  name                 = "cloudshell"
  storage_account_name = azurerm_storage_account.azureCloudShellAccount.name
  quota                = 50
}

resource "azurerm_key_vault" "azureKeyVault" {
  name                            = "${var.keyVaultName}-${random_string.random.result}"
  resource_group_name             = upper("${var.areaPrefix}-${var.azureResourceGroups["keyvaultRG"].name}")
  location                        = var.deployRegion
  enabled_for_disk_encryption     = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled             = true
  purge_protection_enabled        = false
  enabled_for_template_deployment = true
  enabled_for_deployment          = true
  sku_name                        = "standard"

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = azurerm_subnet.azureVnetSubnets.*.id
  }

  tags       = merge(var.basetags, { "Service" = "Azure Security", "location" = "${var.deployRegion}" })
  depends_on = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_recovery_services_vault" "azureBackupVault" {
  name                = var.backupVaultName
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["backupRG"].name}")
  location            = var.deployRegion
  sku                 = "Standard"
  soft_delete_enabled = true
  tags                = merge(var.basetags, { "Service" = "Azure Backup", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_backup_policy_vm" "azureBackupVaultT1Policy" {
  name                = "Tier1BackupPolicy"
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["backupRG"].name}")
  recovery_vault_name = azurerm_recovery_services_vault.azureBackupVault.name
  timezone            = var.deployRegionTimeZone

  backup {
    frequency = "Daily"
    time      = "20:00"
  }
  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 7
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

resource "azurerm_backup_policy_vm" "azureBackupVaultT2Policy" {
  name                = "Tier2BackupPolicy"
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["backupRG"].name}")
  recovery_vault_name = azurerm_recovery_services_vault.azureBackupVault.name
  timezone            = var.deployRegionTimeZone

  backup {
    frequency = "Daily"
    time      = "22:00"
  }
  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 3
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

resource "azurerm_backup_policy_vm" "azureBackupVaultT3Policy" {
  name                = "Tier3BackupPolicy"
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["backupRG"].name}")
  recovery_vault_name = azurerm_recovery_services_vault.azureBackupVault.name
  timezone            = var.deployRegionTimeZone

  backup {
    frequency = "Daily"
    time      = "00:00"
  }
  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 6
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

resource "azurerm_log_analytics_workspace" "azureLogAnalytics" {
  name                = "${var.analyticsName}-${random_string.random.result}"
  resource_group_name = upper("${var.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  location            = var.deployRegion
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_storage_account" "azureFlowLogsAccount" {
  name                     = "flowlogs${random_string.random.result}"
  resource_group_name      = upper("${var.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_network_watcher_flow_log" "azureNetworkFlowLogs" {
  count                     = length(var.azureSubnetRanges)
  network_watcher_name      = azurerm_network_watcher.azureNetworkWatcher.name
  resource_group_name       = upper("${var.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  network_security_group_id = azurerm_network_security_group.azureVnetNsgs[count.index].id
  storage_account_id        = azurerm_storage_account.azureFlowLogsAccount.id
  enabled                   = true
  retention_policy {
    enabled = true
    days    = 7
  }
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.azureLogAnalytics.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.azureLogAnalytics.location
    workspace_resource_id = azurerm_log_analytics_workspace.azureLogAnalytics.id
    interval_in_minutes   = 10
  }
}

resource "azurerm_storage_account" "azurevmDiagnosticsAccount" {
  name                     = "diagnostics${random_string.random.result}"
  resource_group_name      = upper("${var.areaPrefix}-${var.azureResourceGroups["serverRG"].name}")
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

# resource "azurerm_security_center_subscription_pricing" "azureSecurityCenter-standard" {
#   tier = "Standard"
# }

# resource "azurerm_security_center_workspace" "azureSecurityCenter-workspaces" {
#   scope        = data.azurerm_subscription.current.id
#   workspace_id = azurerm_log_analytics_workspace.azureLogAnalytics.id
#   depends_on   = [azurerm_security_center_subscription_pricing.azureSecurityCenter-standard]
# }