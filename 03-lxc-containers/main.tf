
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
  }
}

# Provider
provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  insecure  = var.proxmox.insecure
}

# Resources
resource "proxmox_virtual_environment_container" "lxc" {
  count        = var.container_config.count
  description  = "LXC Container - Managed by Terraform"
  node_name    = var.proxmox.node_name
  vm_id        = var.container_config.starting_vm_id + count.index
  started      = true
  unprivileged = var.container_config.unprivileged

  operating_system {
    template_file_id = var.container_config.template_file
    type             = var.container_config.os_type
  }

  cpu { cores = var.container_config.cpu_cores }

  memory {
    dedicated = var.container_config.memory_mb
    swap      = var.container_config.swap_mb
  }

  disk {
    datastore_id = var.container_config.datastore_id
    size         = var.container_config.disk_size_gb
  }

  network_interface {
    name   = "eth0"
    bridge = var.container_config.network_bridge
  }

  features {
    nesting = var.features.nesting
    fuse    = var.features.fuse
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "shell"
  }

  initialization {
    hostname = var.container_config.count > 1 ? "${var.container_config.name_prefix}-${count.index + 1}" : var.container_config.name_prefix

    dynamic "ip_config" {
      for_each = var.network_config.use_dhcp ? [] : [1]
      content {
        ipv4 {
          address = "${var.network_config.ipv4_base}${var.network_config.ipv4_start + count.index}/${var.network_config.ipv4_cidr}"
          gateway = var.network_config.ipv4_gateway
        }
      }
    }

    user_account {
      keys     = var.auth.ssh_keys
      password = var.auth.root_password
    }
  }

  tags = var.tags
}

# Outputs
output "container_summary" {
  value = {
    count        = var.container_config.count
    hostnames    = [for c in proxmox_virtual_environment_container.lxc : c.initialization[0].hostname]
    ids          = proxmox_virtual_environment_container.lxc[*].id
    ips          = [for c in proxmox_virtual_environment_container.lxc : try(c.initialization[0].ip_config[0].ipv4[0].address, "dhcp")]
    cpu_cores    = var.container_config.cpu_cores
    memory_mb    = var.container_config.memory_mb
    disk_size_gb = var.container_config.disk_size_gb
    unprivileged = var.container_config.unprivileged
  }
}
