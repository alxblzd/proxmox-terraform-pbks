# Terraform Proxmox

Deploy VMs, containers, and clusters on Proxmox VE.

All hostnames, domains, node names, bridges, IP addresses, datastore names, usernames, and tokens in this repository are placeholders. Replace them with values from your own environment before applying.

## Playbooks

| Directory | Description | Template |
|-----------|-------------|----------|
| `01-debian13-vms` | Debian 13 VMs | 9100 |
| `02-ubuntu24-vms` | Ubuntu 24.04 VMs | 9200 |
| `03-lxc-containers` | LXC containers | - |
| `04-k3s-cluster` | K3s cluster | 9100 |
| `05-docker-swarm` | Docker Swarm | 9100 |
| `06-debian-dev-ansible` | Debian + Ansible | 9100 |
| `07-deb-bitwarden-vm` | Debian 13 Bitwarden VM | 9100 |

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
sudo ./create-debian13-template.sh   # Builds fresh 9100 from latest official Debian image
sudo ./create-ubuntu24-template.sh   # Builds fresh 9200 from latest official Ubuntu image
```

Canonical layout:
- `9100`: Debian 13 cloud template
- `9200`: Ubuntu 24 cloud template
- `local-lvm`: build/prewarm scratch storage
- `zfs-pool`: active template and VM storage
- `backup-storage`: backups and exports, not active templates

The template scripts now:
- download the latest official cloud images
- do package upgrade and `qemu-guest-agent` install during template preparation
- prewarm on `local-lvm`, then move the final canonical templates to `zfs-pool`
- keep clone-time cloud-init lightweight for faster Terraform deploys

### Manual Template Refresh

Use this when you want to refresh the current templates by hand instead of using the helper scripts.

1. Make clone-time cloud-init lightweight:

```bash
cat >/var/lib/vz/snippets/base_vm.yaml <<'EOF'
#cloud-config
package_update: false
package_upgrade: false
manage_etc_hosts: true
EOF
```

2. Create a one-time prep snippet that does the heavy work inside the builder VM:

```bash
cat >/var/lib/vz/snippets/template_prep_apt.yaml <<'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent || true
  - cloud-init clean --logs
  - truncate -s 0 /etc/machine-id
  - rm -f /var/lib/dbus/machine-id
  - apt-get clean
  - rm -rf /var/lib/apt/lists/*
power_state:
  mode: poweroff
  timeout: 60
EOF
```

3. Build a temporary Debian builder VM from the latest official image on `local-lvm`:

```bash
cd /var/lib/vz/template-cache
wget -O debian-13-generic-amd64.qcow2 https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2
qm destroy 9910 --purge 1 --destroy-unreferenced-disks 1 2>/dev/null || true
qm create 9910 --name tpl-debian13-build --memory 2048 --cores 1 --cpu host --net0 virtio,bridge=vmbr0,tag=100 --agent enabled=1
qm importdisk 9910 debian-13-generic-amd64.qcow2 local-lvm
qm set 9910 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9910-disk-0
qm set 9910 --ide2 local-lvm:cloudinit --boot order=scsi0 --bootdisk scsi0 --vga std
qm set 9910 --ostype l26 --ciuser ansible --ipconfig0 ip=192.168.100.210/24,gw=192.168.100.1 --cicustom vendor=local:snippets/template_prep_apt.yaml
qm resize 9910 scsi0 +20G
qm start 9910
```

4. Wait until the builder VM powers itself off. That means the package upgrade and `qemu-guest-agent` install are done:

```bash
watch -n 10 'qm status 9910'
```

5. Promote the Debian builder into the canonical template and move it to `zfs-pool`:

```bash
qm template 9910
qm destroy 9100 --purge 1 --destroy-unreferenced-disks 1 2>/dev/null || true
qm clone 9910 9100 --name tpl-debian13-cloud --full --storage local-lvm
qm set 9100 --delete cicustom --delete ipconfig0 --delete ciuser
qm set 9100 --ide2 local-lvm:vm-9100-cloudinit,media=cdrom --agent enabled=1
qm template 9100
qm move-disk 9100 scsi0 zfs-pool --delete 1
qm move-disk 9100 ide2 zfs-pool --delete 1
qm destroy 9910 --purge 1 --destroy-unreferenced-disks 1
```

6. Repeat the same flow for Ubuntu 24 with the official Noble cloud image:

```bash
cd /var/lib/vz/template-cache
wget -O noble-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm destroy 9920 --purge 1 --destroy-unreferenced-disks 1 2>/dev/null || true
qm create 9920 --name tpl-ubuntu24-build --memory 2048 --cores 1 --cpu host --net0 virtio,bridge=vmbr0,tag=100 --agent enabled=1
qm importdisk 9920 noble-server-cloudimg-amd64.img local-lvm
qm set 9920 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9920-disk-0
qm set 9920 --ide2 local-lvm:cloudinit --boot order=scsi0 --bootdisk scsi0 --vga std
qm set 9920 --ostype l26 --ciuser ansible --ipconfig0 ip=192.168.100.211/24,gw=192.168.100.1 --cicustom vendor=local:snippets/template_prep_apt.yaml
qm resize 9920 scsi0 +20G
qm start 9920
```

Then:

```bash
watch -n 10 'qm status 9920'
qm template 9920
qm destroy 9200 --purge 1 --destroy-unreferenced-disks 1 2>/dev/null || true
qm clone 9920 9200 --name tpl-ubuntu24-cloud --full --storage local-lvm
qm set 9200 --delete cicustom --delete ipconfig0 --delete ciuser
qm set 9200 --ide2 local-lvm:vm-9200-cloudinit,media=cdrom --agent enabled=1
qm template 9200
qm move-disk 9200 scsi0 zfs-pool --delete 1
qm move-disk 9200 ide2 zfs-pool --delete 1
qm destroy 9920 --purge 1 --destroy-unreferenced-disks 1
```

7. Sanity-check the result:

```bash
qm config 9100
qm config 9200
zfs list -r zfs-pool | egrep '9100|9200'
```


### Add Snippets 

```bash
cat /var/lib/vz/snippets/base_vm.yaml
#cloud-config
package_update: false
package_upgrade: false
manage_etc_hosts: true
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
proxmox = {
  endpoint    = "https://proxmox.example.com:8006/"
  api_token   = "terraform@pve!automation=REPLACE_ME"
  insecure    = true
  node_name   = "pve01"
  template_id = 9100
}
```

## Commands

```bash
make fmt         # Format all files
make validate    # Validate configs
make clean       # Clean artifacts
```
