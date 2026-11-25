output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_app_id" {
  value = azurerm_subnet.app.id
}

output "subnet_data_id" {
  value = azurerm_subnet.data.id
}

output "lb_backend_pool_id" {
  description = "Pool backend du LB, utilisé par la VM du module compute"
  value       = azurerm_lb_backend_address_pool.app.id
}

output "app_fqdn" {
  description = "Nom DNS public de l'application"
  value       = azurerm_public_ip.lb.fqdn
}
