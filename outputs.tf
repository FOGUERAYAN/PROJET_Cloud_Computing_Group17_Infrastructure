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

output "subnet_func_id" {
  description = "ID du sous-réseau de la Function (pour allowed_subnet_ids d'Hafsatou)"
  value       = module.network.subnet_func_id
}

output "app_url" {
  description = "URL publique de l'application (via le Load Balancer)"
  value       = "http://${module.network.app_fqdn}"
}

output "vm_name" {
  description = "Nom de la VM de l'application"
  value       = module.compute.vm_name
}

output "vm_principal_id" {
  description = "Identité managée de la VM (pour les rôles RBAC)"
  value       = module.compute.principal_id
}

# À ajouter plus tard : nom de la Function.
