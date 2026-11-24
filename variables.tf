variable "project" {
  description = "Nom court du projet, utilisé dans les noms et les tags"
  type        = string
  default     = "cap90"
}

variable "environment" {
  description = "Environnement (prod uniquement pour ce projet)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Région Azure autorisée par l'abonnement Student (à valider)"
  type        = string
  default     = "francecentral"
}

variable "location_short" {
  description = "Abréviation de la région pour les noms de ressources"
  type        = string
  default     = "frc"
}

variable "owner" {
  description = "Valeur du tag owner"
  type        = string
}

# --- Réseau (P1) ---
variable "vnet_address_space" {
  description = "Plage d'adresses du VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_app_prefix" {
  description = "Plage du sous-réseau app (VM)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_data_prefix" {
  description = "Plage du sous-réseau data (accès privé au stockage et au Key Vault)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "app_port" {
  description = "Port d'écoute de l'application (Gunicorn), défini avec Hafsatou"
  type        = number
  default     = 8000
}

# --- Calcul (P1) ---
variable "vm_size" {
  description = "Taille de la VM. La série B est bloquée sur l'abonnement Student en France Central ; plus petite taille autorisée : Standard_F1als_v7 (repli : Standard_D2als_v7)"
  type        = string
  default     = "Standard_F1als_v7"
}
