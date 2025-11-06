# Docker Swarm

Deploy Docker Swarm cluster.

## Deploy

```bash
nano terraform.tfvars
terraform init && terraform apply
./install-docker-swarm.sh
```

## Config

```hcl
manager_count = 1
worker_count  = 2

manager_cpu_cores = 2
manager_memory    = 2048

worker_cpu_cores = 2
worker_memory    = 4096
```

Access Portainer: `http://<MANAGER_IP>:9000`
