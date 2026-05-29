output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.dell_firmware_mirror.vm_id
}

output "vm_ipv4_addresses" {
  description = "VM IPv4 addresses (populated once qemu-guest-agent reports in)"
  value       = proxmox_virtual_environment_vm.dell_firmware_mirror.ipv4_addresses
}
