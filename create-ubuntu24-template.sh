#!/bin/bash
# Ubuntu 24.04 template creator
# Builds a prewarmed template from the latest official Ubuntu cloud image.

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

set -euo pipefail

VMID="${VMID:-9200}"
BUILD_VMID="${BUILD_VMID:-9920}"
MEMORY="${MEMORY:-2048}"
BRIDGE="${BRIDGE:-vmbr0}"
VLAN_TAG="${VLAN_TAG:-100}"
TEMP_IP="${TEMP_IP:-192.168.100.211/24}"
GATEWAY="${GATEWAY:-192.168.100.1}"
BUILD_STORAGE="${BUILD_STORAGE:-local-lvm}"
FINAL_STORAGE="${FINAL_STORAGE:-zfs-pool}"
NAME="${NAME:-tpl-ubuntu24-cloud}"
WORKDIR="${WORKDIR:-/var/lib/vz/template-cache/codex-prewarm}"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_FILE="noble-server-cloudimg-amd64.img"
BASE_SNIPPET="/var/lib/vz/snippets/base_vm.yaml"
PREP_SNIPPET="/var/lib/vz/snippets/template_prep_apt.yaml"

mkdir -p "$WORKDIR" /var/lib/vz/snippets
cd "$WORKDIR"

cat > "$BASE_SNIPPET" <<'EOF'
#cloud-config
package_update: false
package_upgrade: false
manage_etc_hosts: true
EOF

cat > "$PREP_SNIPPET" <<'EOF'
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

echo "Downloading latest official Ubuntu 24.04 cloud image..."
wget -q --show-progress -O "$IMAGE_FILE" "$IMAGE_URL"

qm stop "$BUILD_VMID" --skiplock 1 >/dev/null 2>&1 || true
qm destroy "$BUILD_VMID" --purge 1 --destroy-unreferenced-disks 1 >/dev/null 2>&1 || true

qm create "$BUILD_VMID" --name "${NAME}-build" --memory "$MEMORY" --cores 1 --cpu host --net0 virtio,bridge="$BRIDGE",tag="$VLAN_TAG" --agent enabled=1
qm importdisk "$BUILD_VMID" "$IMAGE_FILE" "$BUILD_STORAGE"
qm set "$BUILD_VMID" --scsihw virtio-scsi-pci --scsi0 "$BUILD_STORAGE:vm-$BUILD_VMID-disk-0"
qm set "$BUILD_VMID" --ide2 "$BUILD_STORAGE:cloudinit" --boot order=scsi0 --bootdisk scsi0 --vga std
qm set "$BUILD_VMID" --ostype l26 --ciuser ansible --ipconfig0 "ip=$TEMP_IP,gw=$GATEWAY" --cicustom "vendor=local:snippets/$(basename "$PREP_SNIPPET")"
qm resize "$BUILD_VMID" scsi0 +20G
qm start "$BUILD_VMID"

echo "Waiting for builder VM $BUILD_VMID to power off after prewarming..."
for _ in $(seq 1 90); do
    if [ "$(qm status "$BUILD_VMID" | awk '{print $2}')" = "stopped" ]; then
        break
    fi
    sleep 10
done

if [ "$(qm status "$BUILD_VMID" | awk '{print $2}')" != "stopped" ]; then
    echo "Builder VM did not stop in time"
    exit 1
fi

qm template "$BUILD_VMID"
qm stop "$VMID" --skiplock 1 >/dev/null 2>&1 || true
qm destroy "$VMID" --purge 1 --destroy-unreferenced-disks 1 >/dev/null 2>&1 || true
qm clone "$BUILD_VMID" "$VMID" --name "$NAME" --full --storage "$BUILD_STORAGE"
if [ "$FINAL_STORAGE" != "$BUILD_STORAGE" ]; then
    qm move-disk "$VMID" scsi0 "$FINAL_STORAGE" --delete 1
    qm move-disk "$VMID" ide2 "$FINAL_STORAGE" --delete 1
fi
qm template "$VMID"
qm stop "$BUILD_VMID" --skiplock 1 >/dev/null 2>&1 || true
qm destroy "$BUILD_VMID" --purge 1 --destroy-unreferenced-disks 1 >/dev/null 2>&1 || true

echo "Created prewarmed template $VMID on $FINAL_STORAGE"

rm -f "$IMAGE_FILE"
echo "Done"
