locals {
  prefixe = "${var.projet}-${var.environnement}"
  etiquettes = {
    projet      = var.projet
    environment = var.environnement
    managed_by  = "terraform"
    owner       = var.proprietaire
  }
}

resource "azurerm_resource_group" "principal" {
  name     = "rg-${local.prefixe}"
  location = var.region
  tags     = local.etiquettes
}

resource "azurerm_virtual_network" "principal" {
  name                = "vnet-${local.prefixe}"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.principal.location
  resource_group_name = azurerm_resource_group.principal.name
  tags                = local.etiquettes
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.principal.name
  virtual_network_name = azurerm_virtual_network.principal.name
  address_prefixes     = ["10.30.1.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-${local.prefixe}-web"
  location            = azurerm_resource_group.principal.location
  resource_group_name = azurerm_resource_group.principal.name

  security_rule {
    name                       = "AutoriserHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AutoriserSSHAdmin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.cidr_admin
    destination_address_prefix = "*"
  }

  tags = local.etiquettes
}

resource "azurerm_public_ip" "web" {
  name                = "pip-${local.prefixe}-web"
  location            = azurerm_resource_group.principal.location
  resource_group_name = azurerm_resource_group.principal.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.etiquettes
}

resource "azurerm_network_interface" "web" {
  name                = "nic-${local.prefixe}-web"
  location            = azurerm_resource_group.principal.location
  resource_group_name = azurerm_resource_group.principal.name

  ip_configuration {
    name                          = "interne"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = local.etiquettes
}

resource "azurerm_network_interface_security_group_association" "web" {
  network_interface_id      = azurerm_network_interface.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "vm-${local.prefixe}-web"
  location                        = azurerm_resource_group.principal.location
  resource_group_name             = azurerm_resource_group.principal.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand(var.chemin_cle_publique))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update
    apt-get install -y nginx
    printf '%s\n' '<h1>${local.prefixe} — déployé par Terraform sur Azure</h1>' > /var/www/html/index.html
    systemctl enable --now nginx
  EOT
  )

  boot_diagnostics {}
  tags = local.etiquettes
}
