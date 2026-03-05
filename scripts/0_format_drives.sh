#!/bin/bash
# may need to be run with "bash 0_format_drives.sh"

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <device>"
    echo "  e.g. $0 vdb"
    exit 1
fi

DEVICE="$1"
DISK="/dev/${DEVICE}"

if [ ! -b "$DISK" ]; then
    echo "Error: $DISK is not a block device"
    exit 1
fi

KEEP=(false false)

if [ -b "${DISK}1" ] && [ -b "${DISK}2" ]; then
    echo "Existing partitions found on $DISK."
    for i in 1 2; do
        PART="${DISK}${i}"
        FSTYPE="$(sudo blkid -s TYPE -o value "$PART" 2>/dev/null || true)"
        if [ -n "$FSTYPE" ]; then
            echo "  $PART: $FSTYPE filesystem detected."
            read -r -p "  Keep existing filesystem on $PART? [Y/n]: " REPLY
            if [[ "${REPLY:-Y}" =~ ^[Yy]$ ]]; then
                KEEP[$((i-1))]=true
            fi
        else
            echo "  $PART: no filesystem detected."
        fi
    done
else
    echo "WARNING: This will create a new GPT label and two equal partitions on $DISK."
    echo "         ALL existing data on $DISK will be destroyed."
    read -r -p "Proceed with partitioning $DISK? [y/N]: " REPLY
    if [[ ! "${REPLY:-N}" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    sudo parted -s "$DISK" \
        mklabel gpt \
        mkpart primary 0% 50% \
        mkpart primary 50% 100%
fi

for i in 1 2; do
    PART="${DISK}${i}"

    # Wait for partition node to appear
    for attempt in $(seq 1 10); do
        [ -b "$PART" ] && break
        sleep 1
    done

    if [ ! -b "$PART" ]; then
        echo "Error: partition $PART did not appear"
        exit 1
    fi

    LABEL="${DEVICE}${i}"
    MOUNTPOINT="/mnt/${LABEL}"

    if [ "${KEEP[$((i-1))]}" = "true" ]; then
        echo "Keeping existing filesystem on $PART."
    else
        read -r -p "Format $PART as ext4 with label $LABEL? This will destroy data on this partition. [y/N]: " REPLY
        if [[ ! "${REPLY:-N}" =~ ^[Yy]$ ]]; then
            echo "Skipping format of $PART."
            continue
        fi
        sudo mkfs.ext4 -F -L "$LABEL" "$PART"
    fi

    if [ "$i" -eq 1 ]; then
        DEFAULT="Y"
        PROMPT="Mount $PART and add to fstab? [Y/n]: "
    else
        DEFAULT="N"
        PROMPT="Mount $PART and add to fstab? [y/N]: "
    fi

    read -r -p "$PROMPT" REPLY
    REPLY="${REPLY:-$DEFAULT}"

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        sudo mkdir -p "$MOUNTPOINT"
        PARTUUID="$(sudo blkid -s PARTUUID -o value "$PART")"
        if grep -q "PARTUUID=${PARTUUID}" /etc/fstab; then
            echo "fstab entry for PARTUUID=${PARTUUID} already exists, skipping."
        else
            echo "PARTUUID=${PARTUUID}  ${MOUNTPOINT}  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
        fi

        echo "Mounting $PART at $MOUNTPOINT..."
        sudo mount "$PART" "$MOUNTPOINT"
    else
        echo "Skipping mount and fstab entry for $PART."
    fi
done

echo "Done. Partitions of $DISK have been processed."
echo "==============/etc/fstab for your convenience:"
cat /etc/fstab
echo "==============="
echo "==============Partition PARTUUID paths for your convenience:"
for i in 1 2; do
    PART="${DISK}${i}"
    PARTUUID="$(sudo blkid -s PARTUUID -o value "$PART")"
    echo "/dev/disk/by-partuuid/$PARTUUID  $PART"
done