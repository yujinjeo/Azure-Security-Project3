# ============================================================
# On-Prem MySQL -> KRC/JPE Azure MySQL Data-in Replication
#
# 중요:
# AzureRM 5.5.0에는 외부 MySQL -> Azure MySQL Flexible Server
# Data-in Replication을 직접 표현하는 azurerm_* resource가 없다.
# Azure 서비스 자체가 Data-in Replication 설정을 MySQL 저장 프로시저
# (mysql.az_replication_change_master / az_replication_start)로 제공하므로,
# Terraform의 built-in terraform_data resource가 각 리전 MGMT VM에서
# 초기 dump/restore + 저장 프로시저 호출을 일관되게 수행한다.
#
# binlog file/position은 하드코딩하지 않는다.
# terraform apply 시 mysqldump --source-data=2가 현재 값을 자동 수집한다.
# ============================================================

locals {
  db_replication_ssh_user = "team3_repl"
}

resource "terraform_data" "krc_data_in_replication" {
  count = var.enable_db_data_in_replication ? 1 : 0

  triggers_replace = [
    var.db_replication_generation,
    var.db_failback_generation,
    module.korea.db_server_id,
    module.korea.mgmt_public_ip,
    var.onprem_db_host,
    var.onprem_db_sync_user,
    var.db_name,
  ]

  connection {
    type        = "ssh"
    host        = module.korea.mgmt_public_ip
    user        = local.db_replication_ssh_user
    private_key = file("${path.root}/region/id_rsa")
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${path.root}/scripts/bootstrap_data_in_replication.sh.tftpl", {
      region_code         = "krc"
      source_host         = var.onprem_db_host
      source_port         = var.onprem_db_port
      source_db           = var.db_name
      source_user         = var.onprem_db_sync_user
      source_password_b64 = base64encode(var.onprem_db_sync_password)
      target_host         = module.korea.db_fqdn
      target_user         = var.db_admin_login
      target_password_b64 = base64encode(var.db_admin_password)
    })
    destination = "/tmp/bootstrap_data_in_replication_krc.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/bootstrap_data_in_replication_krc.sh",
      "/tmp/bootstrap_data_in_replication_krc.sh",
      "rm -f /tmp/bootstrap_data_in_replication_krc.sh",
    ]
  }

  depends_on = [
    module.korea,
    terraform_data.db_failback_to_onprem,
    azurerm_virtual_network_peering.korea_hub_to_japan_spoke,
    azurerm_virtual_network_peering.japan_spoke_to_korea_hub,
  ]
}

resource "terraform_data" "jpe_data_in_replication" {
  count = var.enable_db_data_in_replication ? 1 : 0

  triggers_replace = [
    var.db_replication_generation,
    var.db_failback_generation,
    module.japan.db_server_id,
    module.japan.mgmt_public_ip,
    var.onprem_db_host,
    var.onprem_db_sync_user,
    var.db_name,
  ]

  connection {
    type        = "ssh"
    host        = module.japan.mgmt_public_ip
    user        = local.db_replication_ssh_user
    private_key = file("${path.root}/region/id_rsa")
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${path.root}/scripts/bootstrap_data_in_replication.sh.tftpl", {
      region_code         = "jpe"
      source_host         = var.onprem_db_host
      source_port         = var.onprem_db_port
      source_db           = var.db_name
      source_user         = var.onprem_db_sync_user
      source_password_b64 = base64encode(var.onprem_db_sync_password)
      target_host         = module.japan.db_fqdn
      target_user         = var.db_admin_login
      target_password_b64 = base64encode(var.db_admin_password)
    })
    destination = "/tmp/bootstrap_data_in_replication_jpe.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/bootstrap_data_in_replication_jpe.sh",
      "/tmp/bootstrap_data_in_replication_jpe.sh",
      "rm -f /tmp/bootstrap_data_in_replication_jpe.sh",
    ]
  }

  depends_on = [
    module.japan,
    terraform_data.db_failback_to_onprem,
    terraform_data.krc_data_in_replication,
    azurerm_virtual_network_peering.korea_hub_to_japan_spoke,
    azurerm_virtual_network_peering.japan_spoke_to_korea_hub,
  ]
}
