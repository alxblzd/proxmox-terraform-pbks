#!/bin/bash
# Ubuntu 24.04 template creator
# Creates ID 9210 (with cloudinit) and 9200 (for terraform)

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

VMID_WITH=9210
VMID_WITHOUT=9200
MEMORY=2048
BRIDGE="vmbr2"
STORAGE="vmdata"
SSH_KEY="$HOME/.ssh/authorized_keys"

echo "Downloading Ubuntu 24.04 image..."
wget -q --show-progress https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Create base template with cloudinit
qm create $VMID_WITH --name ubuntu24-cloud --memory $MEMORY --net0 virtio,bridge=$BRIDGE
qm importdisk $VMID_WITH noble-server-cloudimg-amd64.img $STORAGE -format qcow2
qm set $VMID_WITH --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID_WITH-disk-0
qm set $VMID_WITH --ide2 $STORAGE:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0
qm resize $VMID_WITH scsi0 +20G
qm set $VMID_WITH --ipconfig0 ip=10.0.100.10/24,gw=10.0.100.1

if [ -f "$SSH_KEY" ]; then
    qm set $VMID_WITH --sshkey $SSH_KEY
fi

qm template $VMID_WITH
echo "Created template $VMID_WITH with cloudinit"

# Clone for terraform (no cloudinit drive)
qm clone $VMID_WITH $VMID_WITHOUT --name ubuntu24-cloud-template --full
qm set $VMID_WITHOUT --delete ide2
qm template $VMID_WITHOUT
echo "Created template $VMID_WITHOUT without cloudinit (for terraform)"

rm noble-server-cloudimg-amd64.img
echo "Done"
