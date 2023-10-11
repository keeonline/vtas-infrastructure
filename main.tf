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

# # Create the browser host

# resource "azurerm_public_ip" "browser_pip" {
#   name                = "keeonline-browser-pip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
# }

# resource "azurerm_network_interface" "browser_nic" {
#   name                = "keeonline-browser-nic"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "keeonline_browser_nic_config"
#     subnet_id                     = azurerm_subnet.subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.browser_pip.id
#   }
# }

# resource "azurerm_network_security_group" "windows_nsg" {
#   name                = "keeonline-windows-nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_network_security_rule" "windows_nsg_rdp" {
#   name                        = "keeonline-windows-nsg-rdp"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "3389"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.windows_nsg.name
# }

# resource "azurerm_network_interface_security_group_association" "browser_nsg" {
#   network_interface_id      = azurerm_network_interface.browser_nic.id
#   network_security_group_id = azurerm_network_security_group.windows_nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
#   subnet_id       = azurerm_subnet.subnet.id
#   network_security_group_id = azurerm_network_security_group.windows_nsg.id
# }

# resource "azurerm_windows_virtual_machine" "browser_vm" {
#   name = "keeonline-browser-vm"
#   computer_name = "browser-host"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   size = "Standard_B1s"
#   admin_username = "adminuser"
#   admin_password = "avingAg1raffe!"
#   network_interface_ids = [azurerm_network_interface.browser_nic.id]

#   os_disk {
#     name = "keeonline-browser-os-disk"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2022-Datacenter"
#     version   = "latest"
#   }

#   winrm_listener {
#     protocol = "Http"
#   }
# }





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

  custom_data = filebase64("scripts/linux.sh")
}

# resource "azurerm_network_security_group" "vtas_nsg" {
#   name                = "keeonline-vtas-nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_network_security_rule" "vtas_nsg_ssh" {
#   name                        = "keeonline-vtas-nsg-ssh"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.vtas_nsg.name
# }

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
  size = "Standard_B1s"
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

  custom_data = filebase64("scripts/linux.sh")
}

# Create the repository host vm

resource "azurerm_public_ip" "repo_pip" {
  name                = "keeonline-repo-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}


resource "azurerm_network_interface" "repo_nic" {
  name                = "keeonline-repo-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "keeonline_repo_nic_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.repo_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "repo_vm" {
  name = "keeonline-repo-vm"
  computer_name = "repo-host"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
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

  custom_data = filebase64("scripts/repo.sh")
}

# resource "azurerm_network_security_group" "repo_nsg" {
#   name                = "keeonline-repo-nsg"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

# resource "azurerm_network_security_rule" "repo_nsg_ssh" {
#   name                        = "keeonline-repo-nsg-ssh"
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.repo_nsg.name
# }

