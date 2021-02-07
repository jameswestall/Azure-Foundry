provider "azurerm" {
  alias   = "core"
  features {}
  subscription_id = var.core_subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "azurerm" {
  alias   = "spoke"
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

data "azurerm_client_config" "spoke" {
  provider             = azurerm.spoke
}

# Learn our public IP address
data "http" "publicip" {
   url = "http://icanhazip.com"
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
  depends_on          = [azurerm_resource_group.azureResourceGroups, azurerm_network_watcher.azureNetworkWatcher]
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
  address_prefixes     = ["${cidrsubnet(var.project_object.vnetRange, var.project_object.subnetExtraBits, count.index)}"]
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

resource "azurerm_route" "azureVnetRoutes-firewallroute" {
  provider       = azurerm.spoke
  name                = "SPOKE-ROUTE-INTERNET"
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  route_table_name    = format("SPOKE-VNET-RTBL-SUB%02s", count.index + 1)
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = var.core_network_fw_ip
  count                         = var.project_object.subnetCount
  depends_on                    = [azurerm_route_table.azureVnetRoutes]
}

#implemented to avoid issues when completing load balancing.
#https://docs.microsoft.com/en-us/azure/firewall/integrate-lb
resource "azurerm_route" "azureVnetRoutes-firewallroute-assymetricrouting" {
  provider       = azurerm.spoke
  name                = "SPOKE-ROUTE-INTERNET-LB"
  resource_group_name = upper("${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}")
  route_table_name    = format("SPOKE-VNET-RTBL-SUB%02s", count.index + 1)
  address_prefix      = "${var.core_network_fw_public_ip}/32" #TODO - Investigate using cidr() functions to do this a little neater
  next_hop_type       = "Internet"
  count                         = var.project_object.subnetCount
  depends_on                    = [azurerm_route_table.azureVnetRoutes]
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
    ip_rules = [ "${chomp(data.http.publicip.body)}" ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.spoke.tenant_id
    object_id = data.azurerm_client_config.spoke.object_id

    key_permissions = [ "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify" , "wrapKey" ]

    certificate_permissions = [ "backup", "create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "restore", "setissuers", "update" ]

    secret_permissions = [ "backup", "delete", "get", "list", "purge", "recover", "restore" , "set" ]

    storage_permissions = [ "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas" , "update" ]
  }

  tags       = merge(var.basetags, { "Service" = "Azure Security", "location" = "${var.deployRegion}" })
  depends_on = [azurerm_resource_group.azureResourceGroups]
}


resource "azurerm_key_vault_access_policy" "azureKeyVault-ProjectOwnerGroup" {
  provider = azurerm.spoke
  key_vault_id = azurerm_key_vault.azureKeyVault.id
  tenant_id    = var.tenant_id
  object_id    = azuread_group.project-owner-iam-group.id

  key_permissions = [ "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify" , "wrapKey" ]

  certificate_permissions = [ "backup", "create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "restore", "setissuers", "update" ]

  secret_permissions = [ "backup", "delete", "get", "list", "purge", "recover", "restore" , "set" ]

  storage_permissions = [ "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas" , "update" ]
}

resource "azurerm_key_vault_access_policy" "azureKeyVault-ServicePrincipal" {
  provider = azurerm.spoke
  key_vault_id = azurerm_key_vault.azureKeyVault.id
  tenant_id    = var.tenant_id
  object_id = azuread_application.spoke-app.id
  application_id = azuread_application.spoke-app.application_id
  
  key_permissions = [ "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify" , "wrapKey" ]

  certificate_permissions = [ "backup", "create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "restore", "setissuers", "update" ]

  secret_permissions = [ "backup", "delete", "get", "list", "purge", "recover", "restore" , "set" ]

  storage_permissions = [ "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas" , "update" ]
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
  #use_remote_gateways = true

}

resource "azurerm_virtual_network_peering" "core-to-spoke" {
  provider                  = azurerm.core
  name                      = upper("CORE-TO-${var.project_object.areaPrefix}")
  resource_group_name       = var.core_network_rg_name
  virtual_network_name      = var.core_network_name
  remote_virtual_network_id = azurerm_virtual_network.azureVnet.id
  allow_gateway_transit = true
}

resource "random_password" "spoke-service-principal-password" {
  length           = 20
  special          = true
  override_special = "_%@"
  keepers = {
    area_prefix = "${var.project_object.areaPrefix}" // spoke prefixes should ideally remain the same
  }
}

resource "azuread_group" "project-owner-iam-group" {
  name = upper("admin-azure-foundry-${var.project_object.areaPrefix}-owner")
}

resource "azuread_group" "project-contributors-iam-group" {
  name = upper("admin-azure-foundry-${var.project_object.areaPrefix}-contributor")
}

resource "azuread_group" "project-generalusers-iam-group" {
  name = upper("admin-azure-foundry-${var.project_object.areaPrefix}-generaluser")
}

resource "azuread_group" "project-readers-iam-group" {
  name = upper("admin-azure-foundry-${var.project_object.areaPrefix}-reader")
}

resource "azurerm_role_assignment" "project-owner-iam-assignments" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureResourceGroups[count.index].id
  role_definition_name = "Owner"
  principal_id         = azuread_group.project-owner-iam-group.id
  count    = length(var.azureResourceGroups)
}

resource "azurerm_role_assignment" "project-contributor-iam-assignments" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureResourceGroups[count.index].id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.project-contributors-iam-group.id
  count    = length(var.azureResourceGroups)
}

resource "azurerm_role_assignment" "project-readers-iam-assignments" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureResourceGroups[count.index].id
  role_definition_name = "Reader"
  principal_id         = azuread_group.project-readers-iam-group.id
  count    = length(var.azureResourceGroups)
}

resource "azurerm_resource_group" "azureExtraResourceGroups" {
  provider = azurerm.spoke
  name     = upper("${var.project_object.areaPrefix}-${element(values(var.project_object.extraResourceGroups), count.index).name}")
  count    = length(var.project_object.extraResourceGroups)
  location = var.deployRegion
  tags     = merge(var.basetags, element(values(var.project_object.extraResourceGroups), count.index).tags, { "location" = "${var.deployRegion}" })
}

resource "azurerm_role_assignment" "project-owner-iam-assignments-extraresourcegroups" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureExtraResourceGroups[count.index].id
  role_definition_name = "Owner"
  principal_id         = azuread_group.project-owner-iam-group.id
  count    = length(var.project_object.extraResourceGroups)
}

resource "azurerm_role_assignment" "project-contributor-iam-assignments-extraresourcegroups" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureExtraResourceGroups[count.index].id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.project-contributors-iam-group.id
  count    = length(var.project_object.extraResourceGroups)
}

resource "azurerm_role_assignment" "project-reader-iam-assignments-extraresourcegroups" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureExtraResourceGroups[count.index].id
  role_definition_name = "Reader"
  principal_id         = azuread_group.project-readers-iam-group.id
  count    = length(var.project_object.extraResourceGroups)
}

resource "azurerm_role_assignment" "project-generaluser-iam-assignments-extraresourcegroups" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureExtraResourceGroups[count.index].id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.project-generalusers-iam-group.id
  count    = length(var.project_object.extraResourceGroups)
}

resource "azurerm_role_assignment" "project-generaluser-iam-assignments-VMContributor" {
  provider = azurerm.spoke
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.project_object.areaPrefix}-${var.azureResourceGroups["serverRG"].name}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.project-generalusers-iam-group.id
}

resource "azurerm_role_assignment" "project-generaluser-iam-assignments-NetworkContributor" {
  provider = azurerm.spoke
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.project_object.areaPrefix}-${var.azureResourceGroups["networkRG"].name}"
  role_definition_name = "Network Contributor"
  principal_id         = azuread_group.project-generalusers-iam-group.id
}

resource "azurerm_role_assignment" "project-generaluser-iam-assignments-LGAContributor" {
  provider = azurerm.spoke
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.project_object.areaPrefix}-${var.azureResourceGroups["monitoringRG"].name}"
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azuread_group.project-generalusers-iam-group.id
}

resource "azurerm_role_assignment" "project-generaluser-iam-assignments-KVTContributor" {
  provider = azurerm.spoke
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.project_object.areaPrefix}-${var.azureResourceGroups["keyvaultRG"].name}"
  role_definition_name = "Key Vault Contributor"
  principal_id         = azuread_group.project-generalusers-iam-group.id
}

resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = var.project_id
  service_endpoint_name = "${var.project_object.areaPrefix} - Service Principal"
  description = "Managed by Azure Foundry (Terraform)" 
  credentials {
    serviceprincipalid  = azuread_application.spoke-app.application_id
    serviceprincipalkey = random_password.spoke-service-principal-password.result
  }
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = "Sample Subscription"
}


resource "azuread_application" "spoke-app" {
  name = upper("azure-foundry-${var.project_object.areaPrefix}-deployment-sp")
  available_to_other_tenants = false
}

# Create Service Principal associated with the Azure AD App
# sleep is required for getting around this issue: https://github.com/terraform-providers/terraform-provider-azuread/issues/156
# further detail https://github.com/Azure/AKS/issues/1206#issue-493516902
resource "azuread_service_principal" "spoke-app-service-principal" {
  application_id = azuread_application.spoke-app.application_id
}


resource "azurerm_key_vault_secret" "kvs-management-sp-name" {
  provider = azurerm.spoke
  name         = "${var.project_object.areaPrefix}-management-sp-name"
  value        = upper("azure-foundry-${var.project_object.areaPrefix}-deployment-sp")
  key_vault_id = azurerm_key_vault.azureKeyVault.id
}

resource "azurerm_key_vault_secret" "kvs-management-sp-appid" {
  provider = azurerm.spoke
  name         = "${var.project_object.areaPrefix}-management-sp-appid"
  value        = azuread_application.spoke-app.application_id
  key_vault_id = azurerm_key_vault.azureKeyVault.id
}

resource "azurerm_key_vault_secret" "kvs-management-sp-secret" {
  provider = azurerm.spoke
  name         = "${var.project_object.areaPrefix}-management-sp-secret"
  value        = random_password.spoke-service-principal-password.result
  key_vault_id = azurerm_key_vault.azureKeyVault.id
}


# Create Service Principal password
resource "azuread_service_principal_password" "spoke-app-service-principal-pw" {
  service_principal_id = azuread_service_principal.spoke-app-service-principal.id
  value                = random_password.spoke-service-principal-password.result
  end_date_relative    = "17520h"
}

resource "azurerm_role_assignment" "sp-owner-iam-assignments-extraresourcegroups" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureExtraResourceGroups[count.index].id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.spoke-app-service-principal.id
  count    = length(var.project_object.extraResourceGroups)
}

resource "azurerm_role_assignment" "sp-owner-iam-assignments" {
  provider = azurerm.spoke
  scope                = azurerm_resource_group.azureResourceGroups[count.index].id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.spoke-app-service-principal.id
  count    = length(var.azureResourceGroups)
}