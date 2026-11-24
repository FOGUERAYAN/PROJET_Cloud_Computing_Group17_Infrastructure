output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_app_id" {
  value = azurerm_subnet.app.id
}

output "subnet_data_id" {
  value = azurerm_subnet.data.id
}
