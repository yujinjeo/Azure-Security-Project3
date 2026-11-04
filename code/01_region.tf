locals {
  prefix = "07-3team"
}

# ============================================================
# Korea Central : Active
# - WEB/WAS/DB/Storage/ELK/Event Hub
# - Korea Azure MySQL만 생성
# - On-Prem MySQL -> Korea Azure MySQL Data-in Replication
# - VPN Gateway는 02_hybrid 연결을 위해 미리 생성
# ============================================================
module "korea" {
  source = "./region"

  prefix             = local.prefix
  global_name_suffix = var.lab_id
  rgname             = "${local.prefix}-rg-krc"
  location           = "Korea Central"
  region_code        = "krc"
  region_role        = "active"

  hub_cidrs = [
    "10.0.0.0/27",
    "10.0.1.0/24"
  ]

  spoke_cidrs = [
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  gateway_subnet_cidr = "10.0.0.0/27"
  mgmt_subnet_cidr    = "10.0.1.0/24"
  appgw_subnet_cidr   = "10.0.2.0/24"
  web_subnet_cidr     = "10.0.3.0/24"
  was_subnet_cidr     = "10.0.4.0/24"
  db_subnet_cidr      = "10.0.5.0/24"
  proxy_subnet_cidr = "10.0.6.0/24"

  db_host     = "192.168.10.203"
  db_name     = var.db_name
  db_user     = "team3"
  db_password = "It12345!"
  db_proxy_force_standby = var.db_proxy_force_standby


  mgmt_private_ip        = "10.0.1.10"
  internal_lb_private_ip = "10.0.4.100"

  admin_public_ip_cidr = var.admin_public_ip_cidr
  admin_ssh_public_key = var.admin_ssh_public_key

  create_database   = true
  db_admin_login    = var.db_admin_login
  db_admin_password = var.db_admin_password
  external_db_host  = null
  external_db_tls   = false

  create_public_dns_zone = true
  dns_name               = var.dns_name

  is_create_blob = true

  enable_vpn_gateway       = true
  create_onprem_connection = true
  onprem_gateway_public_ip = var.onprem_gateway_public_ip
  onprem_address_spaces    = var.onprem_address_spaces
  vpn_shared_key           = var.vpn_shared_key

  waf_mode            = var.waf_mode
  storage_name_suffix = var.storage_name_suffix
  tags                = var.common_tags
}

# ========================================================
# Japan East : Standby
# - WEB/WAS/AppGW/Storage/ELK/Event Hub
# - Japan Azure MySQL 생성
# - On-Prem MySQL -> Japan Azure MySQL Data-in Replication
# - WAS는 HAProxy를 통해 On-Prem Active / Azure Standby DB 사용
# - Korea 장애 시 Traffic Manager를 통해 Standby 서비스 활성화
# ==========================================================

module "japan" {
  source = "./region"

  prefix             = local.prefix
  global_name_suffix = var.lab_id
  rgname             = "${local.prefix}-rg-jpe"
  location           = "Japan East"
  region_code        = "jpe"
  region_role        = "standby"

  hub_cidrs = [
    "172.16.0.0/27",
    "172.16.1.0/24"
  ]

  spoke_cidrs = [
    "172.16.2.0/24",
    "172.16.3.0/24",
    "172.16.4.0/24",
    "172.16.5.0/24",
    "172.16.6.0/24"
  ]

  gateway_subnet_cidr = "172.16.0.0/27"
  mgmt_subnet_cidr    = "172.16.1.0/24"
  appgw_subnet_cidr   = "172.16.2.0/24"
  web_subnet_cidr     = "172.16.3.0/24"
  was_subnet_cidr     = "172.16.4.0/24"
  db_subnet_cidr      = "172.16.5.0/24"
  proxy_subnet_cidr = "172.16.6.0/24"

  db_host     = "192.168.10.203"
  db_name     = var.db_name
  db_user     = "team3"
  db_password = "It12345!"
  db_proxy_force_standby = var.db_proxy_force_standby


  mgmt_private_ip        = "172.16.1.10"
  internal_lb_private_ip = "172.16.4.100"

  admin_public_ip_cidr = var.admin_public_ip_cidr
  admin_ssh_public_key = var.admin_ssh_public_key

  create_database   = true
  db_admin_login    = var.db_admin_login
  db_admin_password = var.db_admin_password
  external_db_host  = var.onprem_db_host
  external_db_tls   = false

  create_public_dns_zone = false
  dns_name               = var.dns_name

  is_create_blob = false

  enable_vpn_gateway       = false
  create_onprem_connection = false
  onprem_gateway_public_ip = null
  onprem_address_spaces    = []
  vpn_shared_key           = null

  waf_mode            = var.waf_mode
  storage_name_suffix = var.storage_name_suffix
  tags                = var.common_tags
}
