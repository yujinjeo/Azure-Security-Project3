# ============================================================
# Korea
# ============================================================
output "korea_rg_name" { value = module.korea.rg_name }
output "korea_mgmt_public_ip" { value = module.korea.mgmt_public_ip }
output "korea_mgmt_private_ip" { value = module.korea.mgmt_private_ip }
output "korea_appgw_public_ip" { value = module.korea.appgw_public_ip }
output "korea_db_fqdn" { value = module.korea.db_fqdn }
# output "korea_db_private_ip" { value = module.korea.db_private_ip }
output "korea_vpn_public_ip" { value = module.korea.vpn_public_ip }
output "korea_storage_account" { value = module.korea.storage_account_name }
output "korea_waf_policy_name" { value = module.korea.waf_policy_name }

# ============================================================
# Japan East
# ============================================================
output "japan_rg_name" { value = module.japan.rg_name }
output "japan_mgmt_public_ip" { value = module.japan.mgmt_public_ip }
output "japan_mgmt_private_ip" { value = module.japan.mgmt_private_ip }
output "japan_appgw_public_ip" { value = module.japan.appgw_public_ip }
output "japan_storage_account" { value = module.japan.storage_account_name }
output "japan_waf_policy_name" { value = module.japan.waf_policy_name }
output "japan_configured_db_host" { value = module.japan.application_db_host }

# ============================================================
# Global
# ============================================================
output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.tm.fqdn
}

output "dns_name_servers" {
  value = var.enable_custom_dns ? module.korea.dns_name_servers : []
}

 
# ============================================================
# Data-in Replication Terraform Resources
# ============================================================
output "db_data_in_replication_enabled" {
  value = var.enable_db_data_in_replication
}

output "db_replication_source" {
  value = "${var.onprem_db_host}:${var.onprem_db_port}/${var.db_name}"
}

output "korea_db_replication_resource_id" {
  value = var.enable_db_data_in_replication ? terraform_data.krc_data_in_replication[0].id : null
}

output "japan_db_replication_resource_id" {
  value = var.enable_db_data_in_replication ? terraform_data.jpe_data_in_replication[0].id : null
}

# ============================================================
# Controlled Failover / Failback
# ============================================================
output "db_failover_region" {
  value = var.db_failover_region
}

output "db_proxy_force_standby" {
  value = var.db_proxy_force_standby
}

output "db_failover_promote_resource_id" {
  value = var.db_failover_generation > 0 ? terraform_data.db_failover_promote[0].id : null
}

output "db_failback_resource_id" {
  value = var.db_failback_generation > 0 ? terraform_data.db_failback_to_onprem[0].id : null
}
