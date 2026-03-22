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
  for_each = { for vm in var.vms : vm.name => vm }

  name        = each.value.name
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
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
    floating  = each.value.memory_mb
  }

  vga {
    type = "std"
  }

  disk {
    datastore_id = var.datastore_id
    size         = coalesce(each.value.disk_gb, var.disk_size_gb)
    interface    = var.disk_interface
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = each.value.bridge
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
        address = each.value.ip_address
        gateway = split("/", each.value.ip_address)[0] != each.value.ip_address ? cidrhost(each.value.ip_address, 1) : null
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
    count = length(var.vms)
    vms = { for k, v in proxmox_virtual_environment_vm.vm :
      k => {
        name      = v.name
        id        = v.id
        ip        = try(v.ipv4_addresses[1][0], "N/A")
        cpu_cores = v.cpu[0].cores
        memory_mb = v.memory[0].dedicated
      }
    }
  }
}

output "ssh_commands" {
  description = "Ready-to-use SSH commands for each VM"
  value = { for k, v in proxmox_virtual_environment_vm.vm :
    k => "ssh ${var.cloud_init_username}@${try(v.ipv4_addresses[1][0], "pending")}"
  }
}
