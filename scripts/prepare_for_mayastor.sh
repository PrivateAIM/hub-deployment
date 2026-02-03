#!/bin/bash

# Ensure the script runs with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (or with sudo)."
   exit 1
fi

echo "--- Configuring Hugepages ---"
# 1. Enable hugepages
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# 2. Persist hugepages
echo "vm.nr_hugepages = 1024" > /etc/sysctl.d/20-microk8s-hugepages.conf
sysctl --system

echo "--- Loading NVMe-oF Modules ---"
modprobe nvme-tcp

# Persist module
if ! grep -q "nvme-tcp" /etc/modules-load.d/nvme-tcp.conf 2>/dev/null; then
    echo "nvme-tcp" > /etc/modules-load.d/nvme-tcp.conf
    echo "NVMe-TCP module configured to load on boot."
else
    echo "NVMe-TCP already exists in modules-load.d."
fi

echo "--- Verification ---"
echo "Hugepages: $(cat /proc/meminfo | grep HugePages_Total)"
lsmod | grep nvme_tcp && echo "NVMe-TCP module is active."

echo "Ready for Mayastor installation! Make sure to label your node using the following command:"
echo "kubectl label node <node_name> openebs.io/engine=mayastor"