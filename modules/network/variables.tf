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

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_app_prefix" {
  type = string
}

variable "subnet_data_prefix" {
  type = string
}

variable "subnet_func_prefix" {
  description = "Plage du sous-réseau de la Function (Flex Consumption)"
  type        = string
}

variable "app_port" {
  description = "Port de l'application Flask (gunicorn)"
  type        = number
  default     = 8000
}
