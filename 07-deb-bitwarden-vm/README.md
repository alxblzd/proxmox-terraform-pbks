# Debian 13 Bitwarden VM

Deploy a Debian 13 cloud-init VM for Bitwarden.

## Deploy

```bash
nano terraform.tfvars
terraform init && terraform apply
terraform output ssh_command
```

## Config

```hcl
vm = {
  vmid       = 122
  name       = "bitwarden"
  cpu_cores  = 2
  memory_mb  = 4096
  disk_gb    = 30
  ip_address = "192.168.100.70/24"
  bridge     = "vmbr0"
}
```

Template: 9100 | Storage: zfs-pool | VLAN: 100 | User: ansible | Node: pve01

All values in this example are placeholders.
