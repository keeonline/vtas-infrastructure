terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # version = "~>3.0"
      version = "~>2.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "keeonline-tfstate"
      storage_account_name = "tfstate161123"
      container_name       = "tfstate"
      key                  = "core.tfstate"
  }

}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "keeonline-rg"
  location = "uksouth"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "keeonline-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# Create a subnet within the vnet
resource "azurerm_subnet" "subnet" {
  name = "keeonline-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

# Create the VTAS host vm

resource "azurerm_public_ip" "vtas_pip" {
  name                = "keeonline-vtas-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vtas_nic" {
  name                = "keeonline-vtas-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "keeonline_vtas_nic_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vtas_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vtas_vm" {
  name = "keeonline-vtas-vm"
  computer_name = "vtas-host"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size = "Standard_B1s"
  disable_password_authentication = false
  admin_username = "adminuser"
  admin_password = "avingAg1raffe!"
  network_interface_ids = [azurerm_network_interface.vtas_nic.id]

  os_disk {
    name = "keeonline-vtas-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    ansible = "vtas"
  }

  custom_data = filebase64("scripts/vtas.sh")
}
