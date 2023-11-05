output "repo_host_ip_addr" {
  value = azurerm_linux_virtual_machine.repo_vm.public_ip_address
}