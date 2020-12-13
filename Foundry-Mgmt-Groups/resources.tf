resource "azurerm_management_group" "RootManagementGroup" {
  display_name = "${var.customerName} - Root Management Group"
}

resource "azurerm_management_group" "PlatformManagementGroup" {
  display_name               = "${var.customerName} - Platform Management Group"
  parent_management_group_id = azurerm_management_group.RootManagementGroup.id
  subscription_ids           = var.platformSubscriptions
}
resource "azurerm_management_group" "LandingZonesManagementGroup" {
  display_name               = "${var.customerName} - Landing Zones Management Group"
  parent_management_group_id = azurerm_management_group.RootManagementGroup.id
}

resource "azurerm_management_group" "DevManagementGroup" {
  display_name               = "${var.customerName} - Development Management Group"
  parent_management_group_id = azurerm_management_group.LandingZonesManagementGroup.id
  subscription_ids           = var.devSubscriptions
}

resource "azurerm_management_group" "ProdManagementGroup" {
  display_name               = "${var.customerName} - Production Management Group"
  parent_management_group_id = azurerm_management_group.LandingZonesManagementGroup.id
  subscription_ids           = var.prodSubscriptions
}

resource "azurerm_policy_assignment" "azurePolicy-AllowedRegions" {
  name                 = "Allowed Regions"
  scope                = azurerm_management_group.RootManagementGroup.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Regions which users can deploy resources within"
  display_name         = "${var.customerName} - Allowed Regions"

  parameters = <<PARAMETERS
{
  "listOfAllowedLocations": {
    "value": ${var.allowedRegions}
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "azurePolicy-SubscriptionAdmins" {
  name                 = "Deny Custom Sub Admins"
  scope                = azurerm_management_group.RootManagementGroup.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/10ee2ea2-fb4d-45b8-a7e9-a2e770044cd9"
  description          = "Subscriptions should not contain custom administrators"
  display_name         = "${var.customerName} - Deny Custom Subscription Administrators"
}

resource "azurerm_policy_assignment" "azurePolicy-Tagging-Deny-RG" {
  name                 = "RG Tag - ${var.tagList[count.index]}"
  scope                = azurerm_management_group.RootManagementGroup.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Enforces a tag on all resource groups created under the management group"
  display_name         = "${var.customerName} - Enforce Tag on Resource Group - ${var.tagList[count.index]}"
  location             = var.deployRegion
  count                = length(var.tagList)
  parameters           = <<PARAMETERS
{
  "tagName": {
    "value": "${var.tagList[count.index]}"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "azurePolicy-Tagging-Inherit" {
  name                 = "Tag - ${var.tagList[count.index]}"
  scope                = azurerm_management_group.RootManagementGroup.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9ea02ca2-71db-412d-8b00-7c7ca9fcd32d"
  description          = "Inherit tag from resource group if not set"
  display_name         = "${var.customerName} - Inherit Tag from Resource Group - ${var.tagList[count.index]}"
  identity {
    type = "SystemAssigned"
  }
  location   = var.deployRegion
  count      = length(var.tagList)
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "${var.tagList[count.index]}"
  }
}
PARAMETERS
}