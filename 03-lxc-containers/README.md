# LXC Containers

Deploy lightweight Linux containers.

## Deploy

```bash
# Download template on Proxmox
pveam update && pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# Deploy
nano terraform.tfvars
terraform init && terraform apply
```

## Config

```hcl
container_count = 3
cpu_cores       = 1
memory          = 512
disk_size       = 8

features_nesting = false  # true for Docker support
```

Access: `pct enter <ID>`
