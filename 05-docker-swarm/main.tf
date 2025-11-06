
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
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
resource "proxmox_virtual_environment_vm" "manager" {
  count       = var.docker_manager.count
  name        = var.docker_manager.count > 1 ? "${var.docker_manager.name_prefix}-${count.index}" : var.docker_manager.name_prefix
  node_name   = var.proxmox.node_name
  description = "Docker Swarm Manager - Managed by Terraform"

  clone { vm_id = var.proxmox.template_id }
  agent { enabled = true }
  cpu { cores = var.docker_manager.cpu_cores }
  memory { dedicated = var.docker_manager.memory_mb }
  network_device { bridge = "vmbr0" }

  started = true
  tags    = concat(var.tags, ["docker", "manager", "swarm"])
}

resource "proxmox_virtual_environment_vm" "worker" {
  count       = var.docker_worker.count
  name        = var.docker_worker.count > 1 ? "${var.docker_worker.name_prefix}-${count.index}" : var.docker_worker.name_prefix
  node_name   = var.proxmox.node_name
  description = "Docker Swarm Worker - Managed by Terraform"

  clone { vm_id = var.proxmox.template_id }
  agent { enabled = true }
  cpu { cores = var.docker_worker.cpu_cores }
  memory { dedicated = var.docker_worker.memory_mb }
  network_device { bridge = "vmbr0" }

  started = true
  tags    = concat(var.tags, ["docker", "worker", "swarm"])
}

resource "local_file" "docker_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    manager_ips = [for vm in proxmox_virtual_environment_vm.manager : try(vm.ipv4_addresses[1][0], "N/A")]
    worker_ips  = [for vm in proxmox_virtual_environment_vm.worker : try(vm.ipv4_addresses[1][0], "N/A")]
  })
  filename = "${path.module}/docker-inventory.ini"
}

resource "local_file" "docker_install_script" {
  content = templatefile("${path.module}/templates/install-docker-swarm.sh.tpl", {
    manager_ips = [for vm in proxmox_virtual_environment_vm.manager : try(vm.ipv4_addresses[1][0], "N/A")]
    worker_ips  = [for vm in proxmox_virtual_environment_vm.worker : try(vm.ipv4_addresses[1][0], "N/A")]
  })
  filename        = "${path.module}/install-docker-swarm.sh"
  file_permission = "0755"
}

resource "local_file" "portainer_deploy_script" {
  content = templatefile("${path.module}/templates/deploy-portainer.sh.tpl", {
    manager_ips = [for vm in proxmox_virtual_environment_vm.manager : try(vm.ipv4_addresses[1][0], "N/A")]
  })
  filename        = "${path.module}/deploy-portainer.sh"
  file_permission = "0755"
}

# Outputs
output "cluster_summary" {
  sensitive = true
  value = {
    managers = {
      count     = var.docker_manager.count
      names     = proxmox_virtual_environment_vm.manager[*].name
      ids       = proxmox_virtual_environment_vm.manager[*].id
      ips       = [for vm in proxmox_virtual_environment_vm.manager : try(vm.ipv4_addresses[1][0], "N/A")]
      cpu_cores = var.docker_manager.cpu_cores
      memory_mb = var.docker_manager.memory_mb
    }
    workers = {
      count     = var.docker_worker.count
      names     = proxmox_virtual_environment_vm.worker[*].name
      ids       = proxmox_virtual_environment_vm.worker[*].id
      ips       = [for vm in proxmox_virtual_environment_vm.worker : try(vm.ipv4_addresses[1][0], "N/A")]
      cpu_cores = var.docker_worker.cpu_cores
      memory_mb = var.docker_worker.memory_mb
    }
    node = var.proxmox.node_name
  }
}
