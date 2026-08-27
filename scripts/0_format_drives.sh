#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <device>"
    echo "Example: $0 /dev/vdb"
    exit 1
fi

if [ "${EUID}" -eq 0 ]; then
    echo "Run this script as a regular user; it invokes sudo for privileged operations."
    exit 1
fi

case "$1" in
    /dev/*) DISK="$1" ;;
    *) DISK="/dev/$1" ;;
esac

if [ ! -b "$DISK" ]; then
    echo "Error: $DISK is not a block device."
    exit 1
fi

if lsblk -nrpo MOUNTPOINT "$DISK" | grep -qv '^$'; then
    echo "Error: $DISK or one of its partitions is mounted. Unmount it before continuing."
    lsblk "$DISK"
    exit 1
fi

DEVICE_NAME="$(basename "$DISK")"
if [[ "$DEVICE_NAME" =~ [0-9]$ ]]; then
    PARTITION="${DISK}p1"
else
    PARTITION="${DISK}1"
fi

LABEL="${DEVICE_NAME//[^a-zA-Z0-9_-]/-}-data"
MOUNT_POINT="/mnt/${DEVICE_NAME}1"

echo "The following device will be replaced with one GPT partition and one ext4 filesystem:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK"
echo
echo "WARNING: ALL DATA ON $DISK WILL BE DESTROYED."
read -r -p "Type the exact device path '$DISK' to continue: " CONFIRMATION
if [ "$CONFIRMATION" != "$DISK" ]; then
    echo "Aborted."
    exit 0
fi

sudo parted -s "$DISK" \
    mklabel gpt \
    mkpart primary ext4 1MiB 100%
sudo partprobe "$DISK"

for _ in $(seq 1 10); do
    [ -b "$PARTITION" ] && break
    sleep 1
done

if [ ! -b "$PARTITION" ]; then
    echo "Error: partition $PARTITION did not appear."
    exit 1
fi

sudo mkfs.ext4 -F -L "$LABEL" "$PARTITION"
sudo mkdir -p "$MOUNT_POINT"

PARTUUID="$(sudo blkid -s PARTUUID -o value "$PARTITION")"
if ! grep -qE "^[^#]*PARTUUID=${PARTUUID}[[:space:]]" /etc/fstab; then
    echo "PARTUUID=${PARTUUID}  ${MOUNT_POINT}  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab >/dev/null
fi

sudo mount "$MOUNT_POINT"

echo "Prepared $PARTITION and mounted it at $MOUNT_POINT."
echo "Use this mount as the optional MicroK8s data path in scripts/1_microk8s_setup.sh."
