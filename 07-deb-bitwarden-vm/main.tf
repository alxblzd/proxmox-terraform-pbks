terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  insecure  = var.proxmox.insecure
}

data "local_file" "ssh_pub" {
  filename = var.ssh_public_key
}

resource "proxmox_virtual_environment_vm" "vm" {
  vm_id       = var.vm.vmid
  name        = var.vm.name
  node_name   = var.proxmox.node_name
  description = "Debian 13 VM - Managed by Terraform"

  clone {
    vm_id        = var.proxmox.template_id
    full         = true
    datastore_id = var.datastore_id
    retries      = var.clone_retries
  }

  agent {
    enabled = true
    timeout = var.agent_timeout
  }

  cpu {
    cores = var.vm.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm.memory_mb
    floating  = var.vm.memory_mb
  }

  vga {
    type = "std"
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.vm.disk_gb
    interface    = var.disk_interface
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = var.vm.bridge
    vlan_id = var.vlan_id
  }

  initialization {
    interface           = var.cloud_init_interface
    type                = "nocloud"
    vendor_data_file_id = var.vendor_data_file_id

    user_account {
      username = var.cloud_init_username
      password = var.cloud_init_password != "" ? var.cloud_init_password : null
      keys     = [trimspace(data.local_file.ssh_pub.content)]
    }

    ip_config {
      ipv4 {
        address = var.vm.ip_address
        gateway = split("/", var.vm.ip_address)[0] != var.vm.ip_address ? cidrhost(var.vm.ip_address, 1) : null
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  lifecycle {
    ignore_changes = [initialization["user_account"]]
  }

  started = true
  tags    = concat(var.tags, ["debian13"])
}

output "vm_summary" {
  sensitive = true
  value = {
    name      = proxmox_virtual_environment_vm.vm.name
    id        = proxmox_virtual_environment_vm.vm.id
    ip        = try(proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0], "N/A")
    cpu_cores = proxmox_virtual_environment_vm.vm.cpu[0].cores
    memory_mb = proxmox_virtual_environment_vm.vm.memory[0].dedicated
    node      = proxmox_virtual_environment_vm.vm.node_name
  }
}

output "ssh_command" {
  description = "Ready-to-use SSH command for the VM"
  value       = "ssh ${var.cloud_init_username}@${try(proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0], "pending")}"
}
