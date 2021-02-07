output "core_network_id" {
  value = azurerm_virtual_network.azureVnet.id
}

output "core_network_fw_ip" {
  value = azurerm_firewall.azureFirewall.ip_configuration[0].private_ip_address
}

output "core_network_fw_public_ip" {
  value = azurerm_public_ip.azureVnetFirewallIP.ip_address
}

output "core_network_name" {
  value =  azurerm_virtual_network.azureVnet.name
}

output "core_network_rg_name" {
  value = azurerm_virtual_network.azureVnet.resource_group_name
}