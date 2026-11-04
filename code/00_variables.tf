variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "lab_id" {
  type        = string
  description = "동일 구독 내 팀원 리소스 충돌 방지용 실습 번호"
  default     = "4"
}

variable "admin_public_ip_cidr" {
  type        = string
  description = "관리자 SSH/Kibana 접근 허용 공인 IP/CIDR"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "관리 VM/VMSS SSH public key"
}

variable "db_admin_login" {
  type        = string
  description = "Azure MySQL administrator login"
}

variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "Azure MySQL administrator password"
}

variable "waf_mode" {
  type        = string
  description = "Application Gateway WAF mode: Detection 또는 Prevention"
  default     = "Detection"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention."
  }
}

variable "enable_custom_dns" {
  type        = bool
  description = "사용자 소유 Public DNS Zone을 Terraform으로 생성할지 여부"
  default     = true
}

variable "dns_name" {
  type        = string
  description = "Optional public DNS zone name"
  default     = "kmkim.cloud"
}

variable "storage_name_suffix" {
  type        = string
  description = "Storage/Event Hub 전역 고유 이름용 소문자/숫자 suffix"
  default     = "samteam4"
}

variable "onprem_db_host" {
  type        = string
  description = "02_hybrid에서 Japan WAS가 사용할 On-Prem Docker MySQL 주소"
  default     = "192.168.10.203"
}

variable "enable_hybrid_connection" {
  type        = bool
  description = "01에서 BlueMax까지 S2S Connection을 생성할지 여부. 기본 false, 02_hybrid에서 완성 권장"
  default     = true
}

variable "onprem_gateway_public_ip" {
  type        = string
  description = "BlueMax 외부 공인 IP. enable_hybrid_connection=true일 때 사용"
  default     = "1.220.76.4"
  nullable    = true
}

variable "onprem_address_spaces" {
  type        = list(string)
  description = "VPN으로 연결할 온프레미스 대역"
  default     = ["192.168.10.0/24", "192.168.30.0/24"]
}

variable "vpn_shared_key" {
  type        = string
  sensitive   = true
  description = "Azure VPN Gateway <-> BlueMax PSK. 02_hybrid 단계에서 사용"
  default     = "secui098!"
  nullable    = true
}

variable "common_tags" {
  type = map(string)
  default = {
    Project     = "07-3team"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}


variable "kr_rg_name" {
  type = string
  default = "07-3team-rg-krc" 
}

variable "jp_rg_name" {
  type = string
  default = "07-3team-rg-jpe"
}

variable "kr_rg_location" {
  type= string
  default = "Korea Central"
}

variable "jp_rg_location" {
  type = string
  default = "Japan East"
}



# ============================================================
# On-Prem -> Azure MySQL Data-in Replication
# ============================================================
variable "enable_db_data_in_replication" {
  type        = bool
  description = "On-Prem MySQL 데이터를 KRC/JPE Azure MySQL로 자동 초기 적재하고 Data-in Replication을 구성할지 여부"
  default     = true
}

variable "db_replication_generation" {
  type        = number
  description = "Data-in Replication을 의도적으로 재초기화할 때만 값을 증가시킨다. 변경 시 target DB를 source dump로 다시 seed한다."
  default     = 1
}

variable "onprem_db_port" {
  type        = number
  description = "On-Prem MySQL TCP port"
  default     = 3306
}

variable "onprem_db_sync_user" {
  type        = string
  description = "초기 dump와 replication source 접속에 사용할 On-Prem MySQL 계정. SELECT/SHOW VIEW/TRIGGER 및 REPLICATION SLAVE/CLIENT 권한 필요"
  default     = "team3"
}

variable "onprem_db_sync_password" {
  type        = string
  sensitive   = true
  description = "onprem_db_sync_user 비밀번호"
}

variable "db_name" {
  type        = string
  description = "동기화 대상 애플리케이션 데이터베이스"
  default     = "team3db"
}

# ============================================================
# DB Failover / Failback orchestration
# ============================================================
variable "db_failover_region" {
  type        = string
  description = "On-Prem 장애 시 쓰기 Primary로 승격된 Azure DB 리전 (krc 또는 jpe)"
  default     = "krc"

  validation {
    condition     = contains(["krc", "jpe"], var.db_failover_region)
    error_message = "db_failover_region must be krc or jpe."
  }
}

variable "db_failover_generation" {
  type        = number
  description = "실제 DB failover 승격 작업을 실행할 때 증가시키는 세대 번호. 0이면 실행하지 않음."
  default     = 0
}

variable "db_failover_confirmed" {
  type        = bool
  description = "선택한 Azure DB의 기존 Data-in Replication을 중지/해제하여 임시 Primary로 승격하는 작업에 대한 명시적 확인"
  default     = false
}

variable "db_failback_generation" {
  type        = number
  description = "Azure 임시 Primary의 최신 데이터를 On-Prem으로 되돌리고 KRC/JPE replication을 재구성할 때 증가시키는 세대 번호. 0이면 실행하지 않음."
  default     = 0
}

variable "db_failback_confirmed" {
  type        = bool
  description = "Failback 시 On-Prem team3db를 Azure 임시 Primary snapshot으로 교체하는 작업에 대한 명시적 확인"
  default     = false
}

variable "onprem_db_admin_user" {
  type        = string
  description = "Failback restore에 사용할 On-Prem MySQL 관리 계정. 대상 DB DROP/CREATE/INSERT 권한 필요"
  default     = "team3"
}

variable "onprem_db_admin_password" {
  type        = string
  sensitive   = true
  nullable    = true
  default     = null
  description = "onprem_db_admin_user 비밀번호. db_failback_generation > 0일 때 필수"
}

variable "db_proxy_force_standby" {
  type        = bool
  description = "Failback 정합성 작업 중 HAProxy가 복구된 On-Prem으로 자동 복귀하지 않도록 Azure DB만 사용하게 강제"
  default     = false
}
