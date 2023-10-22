terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "keeonline-tfstate"
      storage_account_name = "tfstate161123"
      container_name       = "tfstate"
      key                  = "repo.tfstate"
  }

}

provider "azurerm" {
  features {}
}

# Get a reference to the existing resource
data "azurerm_resource_group" "rg" {
  name = "keeonline-rg"
}

# Get a reference to the existing subnet
data "azurerm_subnet" "subnet" {
  name                 = "keeonline-subnet"
  virtual_network_name = "keeonline-vnet"
  resource_group_name  = "keeonline-rg"
}

resource "azurerm_public_ip" "repo_pip" {
  name                = "keeonline-repo-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}


resource "azurerm_network_interface" "repo_nic" {
  name                = "keeonline-repo-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "keeonline_repo_nic_config"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.repo_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "repo_vm" {
  name = "keeonline-repo-vm"
  computer_name = "repo-host"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size = "Standard_B1s"
  disable_password_authentication = false
  admin_username = "adminuser"
  admin_password = "avingAg1raffe!"
  network_interface_ids = [azurerm_network_interface.repo_nic.id]

  os_disk {
    name = "keeonline-repo-os-disk"
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
    ansible = "repository"
  }

  custom_data = filebase64("scripts/repository.sh")
}
