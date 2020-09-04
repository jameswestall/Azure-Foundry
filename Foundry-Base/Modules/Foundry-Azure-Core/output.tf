output "core_network_id" {
  value = azurerm_virtual_network.azureVnet.id
}

output "core_network_fw_ip" {
  value = azurerm_firewall.azureFirewall.ip_configuration[0].private_ip_address
}