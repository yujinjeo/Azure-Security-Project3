variable "prefix" { type = string }
variable "global_name_suffix" { type = string }
variable "rgname" { type = string }
variable "korea_rgname" {
  type=string
  default = "07-3team-rg-krc"
}
variable "location" { type = string }
variable "region_code" { type = string }

variable "region_role" {
  type = string
  validation {
    condition     = contains(["active", "standby"], var.region_role)
    error_message = "region_role must be active or standby."
  }
}

variable "hub_cidrs" { type = list(string) }
variable "spoke_cidrs" { type = list(string) }

variable "gateway_subnet_cidr" {
  type     = string
  default  = null
  nullable = true
}
variable "mgmt_subnet_cidr" { type = string }
variable "appgw_subnet_cidr" { type = string }
variable "web_subnet_cidr" { type = string }
variable "was_subnet_cidr" { type = string }
variable "proxy_subnet_cidr" {type = string}
variable "db_subnet_cidr" {
  type     = string
  default  = null
  nullable = true
}
variable "mgmt_private_ip" { type = string }


variable "admin_public_ip_cidr" { type = string }
variable "admin_ssh_public_key" { type = string }

variable "create_database" {
  type    = bool
  default = true
}
variable "db_admin_login" { type = string }
variable "db_admin_password" {
  type      = string
  sensitive = true
}
variable "external_db_host" {
  type     = string
  default  = null
  nullable = true
}
variable "external_db_tls" {
  type    = bool
  default = true
}

variable "create_public_dns_zone" {
  type    = bool
  default = true
}
variable "dns_name" { type = string }

variable "enable_vpn_gateway" {
  type    = bool
  default = true
}
variable "create_onprem_connection" {
  type    = bool
  default = true
}
variable "onprem_gateway_public_ip" {
  type     = string
  default  = null
  nullable = true
}
variable "onprem_address_spaces" {
  type    = list(string)
  default = []
}
variable "vpn_shared_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "waf_mode" {
  type    = string
  default = "Detection"
}
variable "storage_name_suffix" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

# 이 그룹에 blob 스토리지를 생성할것인지의 여부
variable "is_create_blob" {
  type = bool
}

variable "blob_dns_zone_name" {
  type = string
  default = "privatelink.blob.core.windows.net"
}

variable "internal_lb_private_ip" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_user"{
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_proxy_force_standby" {
  type        = bool
  description = "true이면 HAProxy가 On-Prem mysql_active를 사용하지 않고 리전 Azure MySQL만 사용"
  default     = false
}
