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
