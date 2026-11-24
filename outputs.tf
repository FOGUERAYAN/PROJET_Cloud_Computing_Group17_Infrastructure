output "resource_group_name" {
  description = "Nom du groupe de ressources principal"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Nom du VNet"
  value       = module.network.vnet_name
}

output "subnet_app_id" {
  description = "ID du sous-réseau app (pour Maroua et Hafsatou)"
  value       = module.network.subnet_app_id
}

output "subnet_data_id" {
  description = "ID du sous-réseau data (private endpoints du stockage / Key Vault)"
  value       = module.network.subnet_data_id
}

# À ajouter en phase 2 : app_url (IP publique du Load Balancer), noms de la VM et de la Function.
