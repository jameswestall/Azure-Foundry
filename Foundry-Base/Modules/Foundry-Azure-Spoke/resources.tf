provider "azurerm" {
  version = "~>2.5.0"
  alias   = "core"
  features {}
  subscription_id = var.core_subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "azurerm" {
  version = "~>2.5.0"
  alias   = "spoke"
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "random_string" "random" {
  length  = 4
  upper   = false
  number  = false
  special = false
}

resource "azurerm_resource_group" "azureResourceGroups" {
  provider = azurerm.spoke
  name     = upper("${var.project_object.areaPrefix}-${element(values(var.azureResourceGroups), count.index).name}")
  count    = length(var.azureResourceGroups)
  location = var.deployRegion
  tags     = merge(var.basetags, element(values(var.azureResourceGroups), count.index).tags, { "location" = "${var.deployRegion}" })
}

resource "azurerm_virtual_network" "azureVnet" {
  provider            = azurerm.spoke
  name                = upper("${var.project_object.areaPrefix}-${var.vnetSuffix}")
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  location            = var.deployRegion
  address_space       = ["${var.project_object.vnetRange}"]
  depends_on          = [azurerm_resource_group.azureResourceGroups]
  tags                = merge(var.basetags, var.azureResourceGroups["networkRG"].tags, { "location" = "${var.deployRegion}" })
}

#TODO: find an elegant method to deploy into a subscription where new doesn't exist; Will bomb out the execution if already present in each subscription. 
#at this point in time, assume that the subscription does NOT have a network watchter. 
resource "azurerm_network_watcher" "azureNetworkWatcher" {
  provider            = azurerm.spoke
  name                = "${var.project_object.areaPrefix}-${var.deployRegion}-networkwatcher"
  location            = var.deployRegion
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  depends_on          = [azurerm_resource_group.azureResourceGroups]
  tags                = merge(var.basetags, var.azureResourceGroups["networkRG"].tags, { "location" = "${var.deployRegion}" })
}

resource "azurerm_subnet" "azureVnetSubnets" {
  provider             = azurerm.spoke
  name                 = format("SPOKE-VNET-SUB%02s", count.index + 1)
  resource_group_name  = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name = upper("${var.project_object.areaPrefix}-${var.vnetSuffix}")
  address_prefix       = cidrsubnet(var.project_object.vnetRange, var.project_object.subnetExtraBits, count.index)
  count                = var.project_object.subnetCount
  depends_on           = [azurerm_virtual_network.azureVnet]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_network_security_group" "azureVnetNsgs" {
  provider            = azurerm.spoke
  name                = format("SPOKE-VNET-NSG-SUB%02s", count.index + 1)
  location            = var.deployRegion
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  count               = var.project_object.subnetCount
  tags                = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_route_table" "azureVnetRoutes" {
  provider                      = azurerm.spoke
  count                         = var.project_object.subnetCount
  name                          = format("SPOKE-VNET-RTBL-SUB%02s", count.index + 1)
  location                      = var.deployRegion
  resource_group_name           = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  disable_bgp_route_propagation = false
  tags                          = merge(var.basetags, { "Service" = "Azure Networking", "location" = "${var.deployRegion}" })
  depends_on                    = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_subnet_route_table_association" "azureVnetRoutesAssociation" {
  provider       = azurerm.spoke
  count          = var.project_object.subnetCount
  subnet_id      = azurerm_subnet.azureVnetSubnets[count.index].id
  route_table_id = azurerm_route_table.azureVnetRoutes[count.index].id
}

resource "azurerm_subnet_network_security_group_association" "azureVnetNsgAssociation" {
  provider                  = azurerm.spoke
  count                     = var.project_object.subnetCount
  subnet_id                 = azurerm_subnet.azureVnetSubnets[count.index].id
  network_security_group_id = azurerm_network_security_group.azureVnetNsgs[count.index].id
}

resource "azurerm_key_vault" "azureKeyVault" {
  provider                        = azurerm.spoke
  name                            = "${var.project_object.areaPrefix}-${var.keyVaultName}-${random_string.random.result}"
  resource_group_name             = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["keyvaultRG"].name}")
  location                        = var.deployRegion
  enabled_for_disk_encryption     = true
  tenant_id                       = var.tenant_id
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


resource "azurerm_log_analytics_workspace" "azureLogAnalytics" {
  provider            = azurerm.spoke
  name                = "${var.project_object.areaPrefix}-${var.analyticsName}-${random_string.random.result}"
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  location            = var.deployRegion
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on          = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_storage_account" "azureFlowLogsAccount" {
  provider                 = azurerm.spoke
  name                     = "flowlogs${random_string.random.result}"
  resource_group_name      = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_network_watcher_flow_log" "azureNetworkFlowLogs" {
  provider                  = azurerm.spoke
  count                     = var.project_object.subnetCount
  network_watcher_name      = azurerm_network_watcher.azureNetworkWatcher.name
  resource_group_name       = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}")
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
  provider                 = azurerm.spoke
  name                     = "vmdiagnostics${random_string.random.result}"
  resource_group_name      = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["serverRG"].name}")
  location                 = var.deployRegion
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.basetags, { "Service" = "Azure Monitoring", "location" = "${var.deployRegion}" })
  depends_on               = [azurerm_resource_group.azureResourceGroups]
}

resource "azurerm_security_center_subscription_pricing" "azureSecurityCenter-standard" {
  provider = azurerm.spoke
  tier     = "Standard"
}

# resource "azurerm_security_center_workspace" "azureSecurityCenter-workspace" {
#   provider = azurerm.spoke
#   scope        = "/subscriptions/${var.subscription_id}"
#   workspace_id = azurerm_log_analytics_workspace.azureLogAnalytics.id
#   depends_on = [azurerm_security_center_subscription_pricing.azureSecurityCenter-standard]
# }

# resource "azurerm_security_center_contact" "azureSecurityCenter-contact" {
#   email = var.secops_detilas.email
#   phone = var.secops_details.phone

#   alert_notifications = true
#   alerts_to_admins    = true
# }


resource "azurerm_virtual_network_peering" "spoke-to-core" {
  provider                  = azurerm.spoke
  name                      = upper("${var.project_object.areaPrefix}-TO-CORE")
  resource_group_name       = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  virtual_network_name      = azurerm_virtual_network.azureVnet.name
  remote_virtual_network_id = var.core_network_id
}

resource "azurerm_virtual_network_peering" "core-to-spoke" {
  provider                  = azurerm.core
  name                      = upper("CORE-TO-${var.project_object.areaPrefix}")
  resource_group_name       = "NETWORK-RG01" //TODO: Pass this in
  virtual_network_name      = "CORE-VNET-01"
  remote_virtual_network_id = azurerm_virtual_network.azureVnet.id
}

resource "random_password" "spoke-service-principal-password" {
  length = 20
  special = true
  override_special = "_%@"
  keepers = {
    area_prefix = "${var.project_object.areaPrefix}" // spoke prefixes should ideally remain the same
  }
}

resource "azuread_application" "spoke-service-principal" {
  name = "${var.project_object.areaPrefix}-deployment-SP"
}

resource "azuread_application_password" "spoke-service-principal-app-password" {
  application_object_id = azuread_application.spoke-service-principal.id
  description           = "Azure Devops Client Secret"
  value                 = random_password.spoke-service-principal-password.result
  end_date              = timeadd(timestamp(), 8760h) //1 Year Validity
}
