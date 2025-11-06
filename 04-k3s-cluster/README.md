# K3s Cluster

Deploy Kubernetes K3s cluster.

## Deploy

```bash
nano terraform.tfvars
terraform init && terraform apply
./install-k3s.sh
```

## Config

```hcl
k3s_master = [
  { name = "k3s-master1", cpu_cores = 2, memory_mb = 2048, ip_address = "10.0.100.12/24", bridge = "vmbr2" }
]

k3s_worker = [
  { name = "k3s-worker1", cpu_cores = 2, memory_mb = 2048, ip_address = "10.0.100.13/24", bridge = "vmbr2" }
]
```

Template: 9100 | VLAN: 100 | User: ansible
