output "vm_name" {
  value = azurerm_linux_virtual_machine.app.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "principal_id" {
  description = "Identité managée de la VM (pour les rôles RBAC de Maroua et Hafsatou)"
  value       = azurerm_linux_virtual_machine.app.identity[0].principal_id
}
