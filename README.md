# Terraform Proxmox

Deploy VMs, containers, and clusters on Proxmox VE.

## Playbooks

| Directory | Description | Template |
|-----------|-------------|----------|
| `01-debian13-vms` | Debian 13 VMs | 9100 |
| `02-ubuntu24-vms` | Ubuntu 24.04 VMs | 9200 |
| `03-lxc-containers` | LXC containers | - |
| `04-k3s-cluster` | K3s cluster | 9100 |
| `05-docker-swarm` | Docker Swarm | 9100 |
| `06-debian-dev-ansible` | Debian + Ansible | 9100 |

## Usage

```bash
cd <playbook>
nano terraform.tfvars
terraform init && terraform apply
```

## Setup

### Install Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Create Templates

```bash
sudo ./create-debian13-template.sh   # Creates 9110 & 9100
sudo ./create-ubuntu24-template.sh   # Creates 9210 & 9200
```

### Create API Token

```bash
pveum role add TerraformProv -privs "Datastore.Allocate Datastore.AllocateSpace VM.Allocate VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.Memory VM.Config.Network VM.Config.Options VM.PowerMgmt"
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role TerraformProv
pveum user token add terraform@pve terraform -expire 0 -privsep 0
```

Add to `terraform.tfvars`:
```hcl
api_token = "terraform@pve!terraform=<token>"
```

## Commands

```bash
make fmt         # Format all files
make validate    # Validate configs
make clean       # Clean artifacts
```
