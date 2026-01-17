output "bastion_host_fqdn" {
  description = "FQDN of the Bastion host"
  value       = azurerm_bastion_host.main.dns_name
}

output "vm_private_ip" {
  description = "Private IP of the kubectl VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_name" {
  description = "Name of the kubectl VM"
  value       = azurerm_linux_virtual_machine.kubectl.name
}

output "bastion_connection_info" {
  description = "Instructions for connecting via Bastion"
  value = {
    bastion_host = azurerm_bastion_host.main.name
    vm_name      = azurerm_linux_virtual_machine.kubectl.name
    username     = "azureuser"
    instructions = "Connect via Azure Portal > Bastion > ${azurerm_linux_virtual_machine.kubectl.name}"
  }
}
