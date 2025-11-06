# Debian Dev (Ansible)

Deploy Debian VMs with Ansible user provisioning.

## Deploy

```bash
nano terraform.tfvars
nano ansible/host_vars/debian-dev.yml
terraform init && terraform apply
```

## Config

**terraform.tfvars:**
```hcl
vm_config = {
  count      = 1
  cpu_cores  = 2
  memory_mb  = 2048
}
```

**ansible/host_vars/debian-dev.yml:**
```yaml
user:
  username: "developer"
  ssh_key: "ssh-rsa AAAA..."
  sudo: true
```

Ansible runs automatically after VM creation.
