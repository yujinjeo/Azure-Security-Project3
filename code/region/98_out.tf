output "rg_name" { value = azurerm_resource_group.rg.name }
output "hub_vnet_id" { value = azurerm_virtual_network.hub_vnet.id }
output "hub_vnet_name" { value = azurerm_virtual_network.hub_vnet.name }
output "spoke_vnet_id" { value = azurerm_virtual_network.spoke_vnet.id }
output "spoke_vnet_name" { value = azurerm_virtual_network.spoke_vnet.name }

output "web_subnet_id" { value = azurerm_subnet.web_subnet.id }

output "mgmt_public_ip" { value = azurerm_public_ip.mgmt_pip.ip_address }
output "mgmt_private_ip" { value = var.mgmt_private_ip }
output "appgw_public_ip" { value = azurerm_public_ip.appgw_pip.ip_address }

output "db_server_id" { value = local.db_server_id }
output "db_fqdn" { value = local.db_fqdn }
output "db_name" { value = local.db_name }
output "application_db_host" { value = local.app_db_host }

output "dns_zone_name" {
  value = var.create_public_dns_zone ? azurerm_dns_zone.public.name : null
}
output "dns_name_servers" {
  value = var.create_public_dns_zone ? azurerm_dns_zone.public.name_servers : []
}

output "vpn_public_ip" {
  value = var.enable_vpn_gateway ? azurerm_public_ip.vpn_pip[0].ip_address : null
}

output "storage_account_id" { value = azurerm_storage_account.app.id }
output "storage_account_name" { value = azurerm_storage_account.app.name }
output "storage_container_name" { value = azurerm_storage_container.appdata.name }

output "waf_policy_name" { value = azurerm_web_application_firewall_policy.waf.name }
