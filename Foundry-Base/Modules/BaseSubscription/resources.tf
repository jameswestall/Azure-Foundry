data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_string" "random" {
  length  = 10
  upper   = false
  number  = false
  special = false
}

resource "azurerm_resource_group" "azureResourceGroups" {
  name     = element(values(var.azureResourceGroups), count.index)
  count    = length(var.azureResourceGroups)
  location = var.deployRegion
  tags     = var.basetags
}

resource "azurerm_virtual_network" "azureVnet" {
  name                = var.vnetName
  resource_group_name = var.azureResourceGroups["networkRG"]
  location            = var.deployRegion
  address_space       = var.vnetRanges
  depends_on          = [azurerm_resource_group.azureResourceGroups]
  tags                = merge(var.basetags, { "service" = "Azure Networking", "location" = "${var.deployRegion}" })
}

resource "azurerm_network_watcher" "azureNetworkWatcher" {
  name                = "${var.deployRegion}-networkwatcher"
  location            = var.deployRegion
  resource_group_name = var.azureResourceGroups["monitoringRG"]
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_network_security_group" "azureVnetNsgs" {
  name                = format("CORE-VNET-NSG-SUB%02s", count.index + 1)
  location            = var.deployRegion
  resource_group_name = var.azureResourceGroups["networkRG"]
  count               = length(var.azureSubnetRanges)
  tags                = merge(var.basetags, { "service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_route_table" "azureVnetRoutes" {
  count                         = length(var.azureSubnetRanges)
  name                          = format("CORE-VNET-RTBL-SUB%02s", count.index + 1)
  location                      = var.deployRegion
  resource_group_name           = var.azureResourceGroups["networkRG"]
  disable_bgp_route_propagation = false
  tags                          = merge(var.basetags, { "service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on                    = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_subnet" "azureVnetSubnets" {
  name                 = format("CORE-VNET-PROD-SUB%02s", count.index + 1)
  resource_group_name  = var.azureResourceGroups["networkRG"]
  virtual_network_name = var.vnetName
  address_prefix       = element(values(var.azureSubnetRanges), count.index)
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
  resource_group_name  = var.azureResourceGroups["networkRG"]
  virtual_network_name = var.vnetName
  address_prefix       = var.azureGWSubnetRange
  depends_on           = [azurerm_virtual_network.azureVnet]
}

resource "azurerm_storage_account" "azureCloudShellAccount" {
  name                     = "cloudshell${random_string.random.result}"
  resource_group_name      = var.azureResourceGroups["cloudShellRG"]
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = merge(var.basetags, { "service" = "Azure Management", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_storage_share" "azureCloudShellShare" {
  name                 = "cloudshell"
  storage_account_name = azurerm_storage_account.azureCloudShellAccount.name
  quota                = 50
}

resource "azurerm_key_vault" "azureKeyVault" {
  name                            = "${var.keyVaultName}-${random_string.random.result}"
  resource_group_name             = var.azureResourceGroups["cloudShellRG"]
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

  tags       = merge(var.basetags, { "service" = "Azure Security", "location" = "${var.deployRegion}" })
  depends_on = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_recovery_services_vault" "azureBackupVault" {
  name                = var.backupVaultName
  resource_group_name = var.azureResourceGroups["backupRG"]
  location            = var.deployRegion
  sku                 = "Standard"
  soft_delete_enabled = true
  tags                = merge(var.basetags, { "service" = "Azure Backup", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_backup_policy_vm" "azureBackupVaultT1Policy" {
  name                = "Tier1BackupPolicy"
  resource_group_name = var.azureResourceGroups["backupRG"]
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
  resource_group_name = var.azureResourceGroups["backupRG"]
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
  resource_group_name = var.azureResourceGroups["backupRG"]
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
  resource_group_name = var.azureResourceGroups["monitoringRG"]
  location            = var.deployRegion
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.basetags, { "service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_storage_account" "azureFlowLogsAccount" {
  name                     = "flowlogs${random_string.random.result}"
  resource_group_name      = var.azureResourceGroups["monitoringRG"]
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_network_watcher_flow_log" "azureNetworkFlowLogs" {
  count                     = length(var.azureSubnetRanges)
  network_watcher_name      = azurerm_network_watcher.azureNetworkWatcher.name
  resource_group_name       = var.azureResourceGroups["monitoringRG"]
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

resource "azuread_group" "azureAdminGroupT3" {
  name = var.azureAdminGroupT3
}

resource "azuread_group" "azureAdminGroupT2" {
  name = var.azureAdminGroupT2
}

resource "azuread_group" "azureAdminGroupT1" {
  name = var.azureAdminGroupT1
}

resource "azurerm_role_assignment" "azureAdminTier3Assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.azureAdminGroupT3.id
}

resource "azurerm_role_assignment" "azureAdminTier2Assignment-1" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.azureAdminGroupT2.id
}

resource "azurerm_role_assignment" "azureAdminTier2Assignment-2" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azuread_group.azureAdminGroupT2.id
}

resource "azurerm_role_assignment" "azureAdminTier1Assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.azureAdminGroupT1.id
}

resource "azurerm_storage_account" "azurevmDiagnosticsAccount" {
  name                     = "diagnostics${random_string.random.result}"
  resource_group_name      = var.azureResourceGroups["serverRG"]
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_security_center_workspace" "azureSecurityCenter" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = azurerm_log_analytics_workspace.azureLogAnalytics.id
}

resource "azurerm_policy_assignment" "azurePolicy-WindowsAnalyticsAssign" {
  name                 = "${var.customerName} - Enforce Windows Log Analytic Enrollment"
  scope                = data.azurerm_subscription.current.id
  location             = var.deployRegion
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0868462e-646c-4fe3-9ced-a733534b6a2c"
  description          = "Enforce Windows Log Analytic Enrollment"
  display_name         = "${var.customerName} - Enforce Windows Log Analytic Enrollment"
  identity {
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
{
  "logAnalytics": {
    "value": "${azurerm_log_analytics_workspace.azureLogAnalytics.id}"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "azurePolicy-LinuxAnalyticsAssign" {
  name                 = "${var.customerName} - Enforce Linux Log Analytic Enrollment"
  scope                = data.azurerm_subscription.current.id
  location             = var.deployRegion
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/053d3325-282c-4e5c-b944-24faffd30d77"
  description          = "Enforce Linux Log Analytic Enrollment"
  display_name         = "${var.customerName} - Enforce Linux Log Analytic Enrollment"
  identity {
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
{
  "logAnalytics": {
    "value": "${azurerm_log_analytics_workspace.azureLogAnalytics.id}"
  }
}
PARAMETERS
}