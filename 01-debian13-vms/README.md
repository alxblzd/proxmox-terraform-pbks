# Debian 13 VMs

Deploy Debian 13 VMs with cloud-init.

## Deploy

```bash
nano terraform.tfvars
terraform init && terraform apply
terraform output ssh_commands
```

## Config

```hcl
vms = [
  {
    name       = "debian13-01"
    cpu_cores  = 2
    memory_mb  = 2048
    ip_address = "192.168.100.30/24"
    bridge     = "vmbr0"
  }
]
```

Template: 9100 | Storage: zfs-pool | VLAN: 100 | User: ansible
