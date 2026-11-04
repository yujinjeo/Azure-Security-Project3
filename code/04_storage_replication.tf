# ============================================================
# Korea -> Japan Storage Object Replication
# ============================================================
resource "azurerm_storage_object_replication" "korea_to_japan" {
  source_storage_account_id      = module.korea.storage_account_id
  destination_storage_account_id = module.japan.storage_account_id

  rules {
    source_container_name      = module.korea.storage_container_name
    destination_container_name = module.japan.storage_container_name
    copy_blobs_created_after   = "Everything"
  }
}
