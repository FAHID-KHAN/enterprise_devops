resource "azurerm_storage_account" "metrics" {
  name                     = "cm${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "snapshots" {
  name                  = "metric-snapshots"
  storage_account_name  = azurerm_storage_account.metrics.name
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name_prefix}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${local.name_prefix}-storage-diag"
  target_resource_id         = azurerm_storage_account.metrics.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "Transaction"
    enabled  = true
  }
}

