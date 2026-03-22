variable "proxmox" {
  type = object({
    endpoint    = string
    api_token   = string
    insecure    = bool
    node_name   = string
    template_id = number
  })
}

variable "k3s_master" {
  type = list(object({
    name       = string
    cpu_cores  = number
    memory_mb  = number
    ip_address = string
    bridge     = string
  }))
}

variable "k3s_worker" {
  type = list(object({
    name       = string
    cpu_cores  = number
    memory_mb  = number
    ip_address = string
    bridge     = string
  }))
}

variable "ssh_public_key" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "k3s"]
}

variable "vlan_id" {
  description = "VLAN ID for VM network interfaces"
  type        = number
  default     = 100
}

variable "dns_servers" {
  description = "DNS servers for cloud-init configuration"
  type        = list(string)
  default     = ["192.168.100.1"]
}

variable "datastore_id" {
  description = "Proxmox datastore for VM disks"
  type        = string
  default     = "zfs-pool"
}

variable "disk_size_gb" {
  description = "Default disk size in GB"
  type        = number
  default     = 20
}

variable "cloud_init_username" {
  description = "Default username for VM access"
  type        = string
  default     = "ansible"
}

variable "cloud_init_password" {
  description = "Default password for console access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vendor_data_file_id" {
  description = "Path to cloud-init vendor data snippet in Proxmox"
  type        = string
  default     = "local:snippets/base_vm.yaml"
}

variable "cloud_init_interface" {
  description = "Interface for cloud-init drive (ide2, scsi0, etc)"
  type        = string
  default     = "ide2"
}

variable "disk_interface" {
  description = "Disk interface type"
  type        = string
  default     = "virtio0"
}

variable "agent_timeout" {
  description = "Timeout for QEMU guest agent"
  type        = string
  default     = "60s"
}

variable "clone_retries" {
  description = "Number of retries for VM cloning operation"
  type        = number
  default     = 3
}
