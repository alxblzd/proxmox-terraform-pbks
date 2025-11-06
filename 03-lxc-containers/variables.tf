variable "proxmox" {
  description = "Proxmox connection settings"
  type = object({
    endpoint   = string
    api_token  = string
    insecure   = bool
    node_name  = string
  })
  default = {
    endpoint   = "https://pvealex01.webguardx.com:8006/"
    api_token  = ""
    insecure   = true
    node_name  = "pvealex"
  }
  sensitive = true
}

variable "container_config" {
  description = "LXC container configuration"
  type = object({
    count           = number
    name_prefix     = string
    starting_vm_id  = number
    template_file   = string
    os_type         = string
    unprivileged    = bool
    cpu_cores       = number
    memory_mb       = number
    swap_mb         = number
    disk_size_gb    = number
    datastore_id    = string
    network_bridge  = string
  })
  default = {
    count           = 1
    name_prefix     = "lxc-container"
    starting_vm_id  = 200
    template_file   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    os_type         = "ubuntu"
    unprivileged    = true
    cpu_cores       = 1
    memory_mb       = 512
    swap_mb         = 512
    disk_size_gb    = 8
    datastore_id    = "local-lvm"
    network_bridge  = "vmbr0"
  }
}

variable "network_config" {
  description = "Network configuration"
  type = object({
    use_dhcp    = bool
    ipv4_base   = string
    ipv4_start  = number
    ipv4_cidr   = number
    ipv4_gateway = string
  })
  default = {
    use_dhcp     = true
    ipv4_base    = "192.168.1."
    ipv4_start   = 100
    ipv4_cidr    = 24
    ipv4_gateway = ""
  }
}

variable "features" {
  description = "Container features"
  type = object({
    nesting = bool
    fuse    = bool
  })
  default = {
    nesting = false
    fuse    = false
  }
}

variable "auth" {
  description = "Authentication configuration"
  type = object({
    ssh_keys      = list(string)
    root_password = string
  })
  default = {
    ssh_keys      = []
    root_password = null
  }
  sensitive = true
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "lxc"]
}
