variable "name_suffix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "subnet_app_id" {
  description = "Sous-réseau de la VM (sortie du module network)"
  type        = string
}

variable "lb_backend_pool_id" {
  description = "Pool backend du Load Balancer (sortie du module network)"
  type        = string
}

variable "vm_size" {
  description = "Taille de la VM (série B bloquée sur Azure for Students)"
  type        = string
  default     = "Standard_F1als_v7"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "app_port" {
  description = "Port de l'application sur la VM"
  type        = number
  default     = 8000
}
