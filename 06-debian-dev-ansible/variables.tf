variable "proxmox" {
  description = "Proxmox connection settings"
  type = object({
    endpoint    = string
    api_token   = string
    insecure    = bool
    node_name   = string
    template_id = number
  })
  default = {
    endpoint    = "https://pvealex01.webguardx.com:8006/"
    api_token   = ""
    insecure    = true
    node_name   = "pvealex"
    template_id = 9100
  }
  sensitive = true
}

variable "vm_config" {
  description = "VM configuration"
  type = object({
    count       = number
    name_prefix = string
    cpu_cores   = number
    memory_mb   = number
  })
  default = {
    count       = 1
    name_prefix = "debian-dev"
    cpu_cores   = 2
    memory_mb   = 2048
  }
}

variable "ansible_config" {
  description = "Ansible configuration"
  type = object({
    run_after_create = bool
  })
  default = {
    run_after_create = true
  }
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "managed", "debian", "dev"]
}
