terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
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

resource "azurerm_windows_virtual_machine" "vtas_vm" {
  name = "keeonline-vtas-vm"
  computer_name = "vtas-host"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size = "Standard_B2s"
  admin_username = "adminuser"
  admin_password = "avingAg1raffe!"
  network_interface_ids = [azurerm_network_interface.vtas_nic.id]

  os_disk {
    name = "keeonline-vtas-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }
}

resource "azurerm_network_security_group" "vtas_nsg" {
  name                = "keeonline-vtas-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "vtas_nsg_rdp" {
  name                        = "keeonline-vtas-nsg-rdp"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vtas_nsg.name
}


# Create the application host vm

resource "azurerm_public_ip" "app_pip" {
  name                = "keeonline-app-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}


resource "azurerm_network_interface" "app_nic" {
  name                = "keeonline-app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "keeonline_app_nic_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name = "keeonline-app-vm"
  computer_name = "app-host"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size = "Standard_B2s"
  disable_password_authentication = false
  admin_username = "adminuser"
  admin_password = "avingAg1raffe!"
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  os_disk {
    name = "keeonline-app-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "keeonline-app-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "app_nsg_ssh" {
  name                        = "keeonline-app-nsg-ssh"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# Create the ACR

resource "azurerm_container_registry" "acr" {
  name                = "keeonlineacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

# Create the fileshare

resource "azurerm_storage_account" "fs_sa" {
  name                     = "keeonlinefssa"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fs" {
  name                 = "keeonline-fs"
  storage_account_name = azurerm_storage_account.fs_sa.name
  quota                = 5
}

resource "azurerm_storage_share_directory" "fs_dir_vtas" {
  name                 = "vtas-binaries"
  share_name           = azurerm_storage_share.fs.name
  storage_account_name = azurerm_storage_account.fs_sa.name
}