output "vtas_host_ip_addr" {
  value = azurerm_linux_virtual_machine.vtas_vm.public_ip_address
}