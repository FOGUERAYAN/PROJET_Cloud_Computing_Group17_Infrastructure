variable "resource_group_name" {
  description = "Nom du groupe de ressources (rg-cap90-prod-frc)"
  type        = string
}

variable "location" {
  description = "Région Azure (francecentral)"
  type        = string
}

variable "tags" {
  description = "Tags obligatoires : owner, project, environment"
  type        = map(string)
}

variable "subnet_data_id" {
  description = "ID du sous-réseau snet-data (10.0.2.0/24) qui reçoit le private endpoint blob"
  type        = string
}

variable "allowed_subnet_ids" {
  description = "Sous-réseaux autorisés par les règles réseau du compte (snet-app, snet-data)"
  type        = list(string)
  default     = []
}

variable "allowed_ips" {
  description = "IP publiques ou plages CIDR autorisées (ex. IP du déployeur)"
  type        = list(string)
  default     = []
}

variable "principal_ids" {
  description = "Object IDs Entra ID qui reçoivent les rôles data-plane. Liste vide : aucune attribution (gérée par le module sécurité)"
  type        = list(string)
  default     = []
}

variable "name_prefix" {
  description = "Préfixe du nom du compte : st<name_prefix>frc"
  type        = string
  default     = "cap90prod"

  validation {
    condition     = can(regex("^[a-z0-9]{1,19}$", var.name_prefix))
    error_message = "name_prefix : minuscules et chiffres uniquement, 19 caractères max (le nom final st<prefix>frc ne doit pas dépasser 24)."
  }
}

variable "create_private_endpoint" {
  description = "Crée le private endpoint blob dans snet-data et la zone DNS privée associée"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Accès par le point de terminaison public (filtré par les règles réseau, default_action = Deny)"
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Autorise l'authentification par clé partagée. false est plus strict (voir README)"
  type        = bool
  default     = true
}
