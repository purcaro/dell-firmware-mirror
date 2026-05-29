terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# Download Ubuntu 24.04 LTS (Noble) cloud image to Proxmox
resource "proxmox_virtual_environment_download_file" "ubuntu_noble" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.proxmox_node
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.img"
  overwrite    = false
}

# Upload cloud-init user-data as a Proxmox snippet
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml", {
      repo_url      = var.repo_url
      mirror_device = "/dev/vdb"
    })
    file_name = "dell-firmware-mirror-cloud-init.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "dell_firmware_mirror" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  tags      = ["dell-firmware-mirror", "ubuntu-24"]

  cpu {
    cores   = var.cpu_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_mb
  }

  # OS disk — cloned from Ubuntu cloud image
  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.ubuntu_noble.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.os_disk_gb
  }

  # Dedicated mirror data disk
  disk {
    datastore_id = var.vm_datastore
    interface    = "virtio1"
    iothread     = true
    discard      = "on"
    size         = var.mirror_disk_gb
    file_format  = "raw"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.vm_ipv4_cidr != "" ? var.vm_ipv4_cidr : "dhcp"
        gateway = var.vm_ipv4_cidr != "" ? var.vm_gateway : null
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  agent {
    enabled = true
    trim    = true
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["virtio0"]

  lifecycle {
    # Avoid VM recreation when cloud-init snippet is regenerated
    ignore_changes = [initialization[0].user_data_file_id]
  }
}
