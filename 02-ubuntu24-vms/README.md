# Ubuntu 24.04 LTS VMs

Deploy Ubuntu 24.04 LTS VMs with cloud-init.

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
    name       = "ubuntu-01"
    cpu_cores  = 2
    memory_mb  = 2048
    ip_address = "10.0.100.40/24"
    bridge     = "vmbr2"
  }
]
```

Template: 9200 | VLAN: 100 | User: ubuntu
