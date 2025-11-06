
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
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
resource "proxmox_virtual_environment_vm" "vm" {
  count       = var.vm_config.count
  name        = var.vm_config.count > 1 ? "${var.vm_config.name_prefix}-${count.index}" : var.vm_config.name_prefix
  node_name   = var.proxmox.node_name
  description = "Debian 13 Dev VM - Managed by Terraform"

  clone { vm_id = var.proxmox.template_id }
  agent { enabled = true }
  cpu { cores = var.vm_config.cpu_cores }
  memory { dedicated = var.vm_config.memory_mb }
  network_device { bridge = "vmbr0" }

  started = true
  tags    = var.tags
}

resource "null_resource" "ansible_provisioner" {
  count = var.ansible_config.run_after_create ? 1 : 0

  depends_on = [proxmox_virtual_environment_vm.vm]

  provisioner "local-exec" {
    command     = "cd ansible && ./run-ansible.sh || true"
    working_dir = path.module
  }

  triggers = {
    vm_ids = join(",", proxmox_virtual_environment_vm.vm[*].id)
  }
}

# Outputs
output "vm_summary" {
  sensitive = true
  value = {
    count     = var.vm_config.count
    names     = proxmox_virtual_environment_vm.vm[*].name
    ids       = proxmox_virtual_environment_vm.vm[*].id
    ips       = [for vm in proxmox_virtual_environment_vm.vm : try(vm.ipv4_addresses[1][0], "N/A")]
    cpu_cores = var.vm_config.cpu_cores
    memory_mb = var.vm_config.memory_mb
    node      = var.proxmox.node_name
  }
}
