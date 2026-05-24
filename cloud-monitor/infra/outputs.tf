output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.demo.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.metrics.name
}

output "storage_container_name" {
  value = azurerm_storage_container.snapshots.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

