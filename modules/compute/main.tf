# Module compute : VM Linux sans IP publique, derrière le Load Balancer.

# Clé SSH générée par Terraform (aucun port 22 ouvert : accès d'urgence par la console série Azure)
resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_app_id
    private_ip_address_allocation = "Dynamic"
  }
}

# La carte réseau rejoint le pool du Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "vm" {
  network_interface_id    = azurerm_network_interface.vm.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.lb_backend_pool_id
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "vm-${var.name_suffix}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm.id]
  disk_controller_type  = "NVMe"
  custom_data           = base64encode(templatefile("${path.module}/cloud-init.yaml", { app_port = var.app_port }))
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # Ubuntu 24.04 LTS Gen2 (obligatoire pour la série v7)
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Diagnostics de démarrage (stockage géré par Azure) : permet la console série
  boot_diagnostics {}
}
