variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.1.10:8006"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form 'user@realm!tokenid=secret'"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (needed for self-signed Proxmox certificates)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name to place the VM on"
  type        = string
  default     = "pve"
}

variable "iso_datastore" {
  description = "Datastore for the Ubuntu cloud image (must allow ISO content)"
  type        = string
  default     = "local"
}

variable "snippets_datastore" {
  description = "Datastore for cloud-init snippets (must allow Snippets content)"
  type        = string
  default     = "local"
}

variable "vm_datastore" {
  description = "Datastore for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_name" {
  description = "VM display name in Proxmox"
  type        = string
  default     = "dell-firmware-mirror"
}

variable "vm_id" {
  description = "Proxmox VM ID (must be unique on the node)"
  type        = number
  default     = 200
}

variable "cpu_cores" {
  description = "Number of vCPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "RAM in MiB"
  type        = number
  default     = 4096
}

variable "os_disk_gb" {
  description = "OS root disk size in GiB"
  type        = number
  default     = 20
}

variable "mirror_disk_gb" {
  description = "Dedicated data disk size in GiB for firmware mirror files"
  type        = number
  default     = 200
}

variable "network_bridge" {
  description = "Proxmox bridge to attach the VM NIC to"
  type        = string
  default     = "vmbr0"
}

variable "vm_ipv4_cidr" {
  description = "Static IPv4 in CIDR notation, e.g. 192.168.1.50/24. Leave empty for DHCP."
  type        = string
  default     = ""
}

variable "vm_gateway" {
  description = "Default gateway when using a static IP"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key to authorise on the ubuntu user"
  type        = string
}

variable "repo_url" {
  description = "HTTPS URL of the dell-firmware-mirror repo to clone onto the VM"
  type        = string
  default     = "https://github.com/purcaro/dell-firmware-mirror.git"
}
