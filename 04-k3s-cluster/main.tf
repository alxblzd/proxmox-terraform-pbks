terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86"
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

resource "proxmox_virtual_environment_vm" "master" {
  for_each = { for vm in var.k3s_master : vm.name => vm }

  name      = each.value.name
  node_name = var.proxmox.node_name
  description = "K3s Master Node"

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
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
    interface    = var.disk_interface
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge = each.value.bridge
    vlan_id = var.vlan_id
  }

 # cloud-init config
  initialization {
    interface           = var.cloud_init_interface
    type                = "nocloud"
    vendor_data_file_id = var.vendor_data_file_id

    user_account {
      username = var.cloud_init_username
      #password = var.cloud_init_password
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

  # cloud-init SSH keys will cause a forced replacement, this is expected
  # behavior see https://github.com/bpg/terraform-provider-proxmox/issues/373
  lifecycle {
    ignore_changes = [initialization["user_account"], ]
  }


  started = true
  tags    = concat(var.tags, ["k3s", "master", "debian"])
}

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = { for vm in var.k3s_worker : vm.name => vm }

  name      = each.value.name
  node_name = var.proxmox.node_name
  description = "K3s Worker Node"

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
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
    interface    = var.disk_interface
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge = each.value.bridge
    vlan_id = var.vlan_id
  }

  initialization {
    interface           = var.cloud_init_interface
    type                = "nocloud"
    vendor_data_file_id = var.vendor_data_file_id

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = split("/", each.value.ip_address)[0] != each.value.ip_address ? cidrhost(each.value.ip_address, 1) : null
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = var.cloud_init_username
      #password = var.cloud_init_password
      keys     = [trimspace(data.local_file.ssh_pub.content)]
    }
  }

  started = true
  tags    = concat(var.tags, ["k3s", "worker", "debian"])
}

output "cluster_summary" {
  sensitive = true
  value = {
    masters = {
      count = length(var.k3s_master)
      names = [for m in proxmox_virtual_environment_vm.master : m.name]
      ips   = [for m in proxmox_virtual_environment_vm.master : try(m.ipv4_addresses[1][0], "N/A")]
      cpu_cores = [for m in var.k3s_master : m.cpu_cores]
      memory_mb = [for m in var.k3s_master : m.memory_mb]
    }
    workers = {
      count = length(var.k3s_worker)
      names = [for w in proxmox_virtual_environment_vm.worker : w.name]
      ips   = [for w in proxmox_virtual_environment_vm.worker : try(w.ipv4_addresses[1][0], "N/A")]
      cpu_cores = [for w in var.k3s_worker : w.cpu_cores]
      memory_mb = [for w in var.k3s_worker : w.memory_mb]
    }
  }
}
