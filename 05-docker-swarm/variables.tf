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

variable "docker_manager" {
  description = "Docker Swarm manager configuration"
  type = object({
    count       = number
    name_prefix = string
    cpu_cores   = number
    memory_mb   = number
  })
  default = {
    count       = 1
    name_prefix = "docker-manager"
    cpu_cores   = 2
    memory_mb   = 2048
  }
  validation {
    condition     = contains([1, 3, 5, 7], var.docker_manager.count)
    error_message = "Manager count must be 1, 3, 5, or 7"
  }
}

variable "docker_worker" {
  description = "Docker Swarm worker configuration"
  type = object({
    count       = number
    name_prefix = string
    cpu_cores   = number
    memory_mb   = number
  })
  default = {
    count       = 3
    name_prefix = "docker-worker"
    cpu_cores   = 2
    memory_mb   = 4096
  }
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "managed"]
}
