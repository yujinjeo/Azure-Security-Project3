# ============================================================
# Controlled DB Failover / Failback orchestration
#
# Normal:   On-Prem -> KRC/JPE continuous Data-in Replication
# Failover: HAProxy automatically uses Azure backup when On-Prem is down.
#           This resource can explicitly detach the selected Azure DB from the
#           old source so it becomes a temporary writable Primary.
# Failback: force HAProxy to remain on Azure, copy the latest Azure Primary
#           snapshot back to On-Prem, then 05_db_data_in_replication.tf
#           automatically reseeds KRC/JPE and resumes continuous replication.
# ============================================================

locals {
  failover_mgmt_public_ip = var.db_failover_region == "krc" ? module.korea.mgmt_public_ip : module.japan.mgmt_public_ip
  failover_db_fqdn        = var.db_failover_region == "krc" ? module.korea.db_fqdn : module.japan.db_fqdn
}

resource "terraform_data" "db_failover_promote" {
  count = var.db_failover_generation > 0 ? 1 : 0

  triggers_replace = [
    var.db_failover_generation,
    var.db_failover_region,
    local.failover_db_fqdn,
  ]

  lifecycle {
    precondition {
      condition     = var.db_failover_confirmed
      error_message = "db_failover_confirmed=true is required because this operation stops/removes the existing Data-in Replication relationship on the selected Azure DB."
    }
  }

  connection {
    type        = "ssh"
    host        = local.failover_mgmt_public_ip
    user        = "team3"
    private_key = file("${path.root}/region/id_rsa")
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${path.root}/scripts/promote_azure_db.sh.tftpl", {
      region_code         = var.db_failover_region
      target_host         = local.failover_db_fqdn
      target_user         = var.db_admin_login
      target_password_b64 = base64encode(var.db_admin_password)
    })
    destination = "/tmp/promote_azure_db.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/promote_azure_db.sh",
      "/tmp/promote_azure_db.sh",
      "rm -f /tmp/promote_azure_db.sh",
    ]
  }

  depends_on = [module.korea, module.japan]
}

resource "terraform_data" "db_failback_to_onprem" {
  count = var.db_failback_generation > 0 ? 1 : 0

  triggers_replace = [
    var.db_failback_generation,
    var.db_failover_region,
    local.failover_db_fqdn,
    var.onprem_db_host,
    var.db_name,
  ]

  lifecycle {
    precondition {
      condition     = var.db_failback_confirmed
      error_message = "db_failback_confirmed=true is required because failback replaces the On-Prem application database with the selected Azure failover snapshot."
    }
    precondition {
      condition     = var.db_proxy_force_standby
      error_message = "Set db_proxy_force_standby=true before failback so application writes remain on Azure while On-Prem is being synchronized."
    }
    precondition {
      condition     = coalesce(var.onprem_db_admin_password, "") != ""
      error_message = "onprem_db_admin_password must be provided when db_failback_generation > 0."
    }
  }

  connection {
    type        = "ssh"
    host        = local.failover_mgmt_public_ip
    user        = "team3"
    private_key = file("${path.root}/region/id_rsa")
    timeout     = "20m"
  }

  provisioner "file" {
    content = templatefile("${path.root}/scripts/failback_to_onprem.sh.tftpl", {
      region_code              = var.db_failover_region
      azure_host               = local.failover_db_fqdn
      azure_user               = var.db_admin_login
      azure_password_b64       = base64encode(var.db_admin_password)
      onprem_host              = var.onprem_db_host
      onprem_port              = var.onprem_db_port
      db_name                  = var.db_name
      onprem_admin_user        = var.onprem_db_admin_user
      onprem_admin_password_b64 = base64encode(coalesce(var.onprem_db_admin_password, ""))
    })
    destination = "/tmp/failback_to_onprem.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/failback_to_onprem.sh",
      "/tmp/failback_to_onprem.sh",
      "rm -f /tmp/failback_to_onprem.sh",
    ]
  }

  depends_on = [
    module.korea,
    module.japan,
    terraform_data.db_failover_promote,
  ]
}
