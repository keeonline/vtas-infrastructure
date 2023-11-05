output "vtas_host_ip_addr" {
  value = azurerm_linux_virtual_machine.vtas_vm.private_ip_address
}