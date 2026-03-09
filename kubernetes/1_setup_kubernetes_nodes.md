# 1 — K8s Node Setup for FLAME

> **Part 1 of 3** — [2: Storage Replication](2_setup_storage_replication.md) · [3: Install FLAME Hub Chart](3_install_flame_hub_chart.md)

## Table of Contents

- [Prepare Drives](#prepare-drives-optional)
- [MicroK8s on a Debian-based System](#microk8s-on-a-debian-based-system)
  - [Automatic Installation Script](#automatic-installation-script-)
  - [1. Storage](#1-storage)
  - [2. Install MicroK8s using Snap](#2-install-microk8s-using-snap)
  - [3. Add /snap/bin to PATH](#3-add-snapbin-to-path)
  - [4. Configure Roles and Permissions](#4-configure-roles-and-permissions)
  - [5. Enable Recommended Addons](#5-enable-recommended-addons)
  - [6. Export Kube Config](#6-export-kube-config)
  - [kubectl Alias](#accessing-the-cluster-using-kubectl)
- [Minikube](#minikube)
- [Helm](#helm)
- [Next Steps](#next-steps)

---

## Prepare Drives (optional)
**For multi-node setups with storage-replication**

If you plan to use a dedicated drive (or partition) for Kubernetes storage, format and mount it **before** installing MicroK8s.

The helper script `scripts/0_format_drives.sh` partitions a disk into two equal GPT partitions, formats them as ext4, and optionally mounts them via `/etc/fstab`.

> Only run this on devices that are unused

```bash
bash scripts/0_format_drives.sh <device>
# e.g. bash scripts/0_format_drives.sh vdb
```

The script will:
* Create two equal-sized GPT partitions (or detect existing ones)
* Format each partition as ext4 (unless you choose to keep existing filesystems)
* Optionally mount the partitions and add them to `/etc/fstab`

> **Tip:** The first partition is a good candidate for MicroK8s storage (see [Storage](#1-storage) below). If you intend to use Mayastor replicated storage later, leave the second partition unmounted — it will be used as a Mayastor disk pool (see [Part 2](2_setup_storage_replication.md)).

---

## MicroK8s on a Debian-based System
**For actual deployments** 
### Automatic Installation Script 🤖
Instead of following the manual steps below, you can run:
> The script has been tested on Debian.

```
./scripts/1_microk8s_setup.sh
```
This script will optionally:
* Set up a non-default MicroK8s storage path (see [Storage](#1-storage))
* Install Snap and MicroK8s
* Configure roles and permissions
* Export Kubeconfig
* Add /snap/bin to PATH

### 1. Storage
If you want to use a non-default path for MicroK8s storage, set this up **before** installing MicroK8s.

With the hostpath-storage addon enabled, your cluster will provision Persistent Volumes using the default StorageClass `microk8s-hostpath`. This will use your SNAP_COMMON directory at `/var/snap/microk8s/common`.

If you want your PVs to be located in another location (e.g. another drive), you can either:

a) Create a new StorageClass and make it the default (note: running MicroK8s in Snap restricts filesystem access).

b) Mount (or symlink) the SNAP_COMMON directory to your preferred destination:
```
sudo mount --bind /mnt/vdb1/microk8s/common /var/snap/microk8s/common

# for persistence
echo "/mnt/vdb1/microk8s/common /var/snap/microk8s/common none bind 0 0" | sudo tee -a /etc/fstab
```

### 2. Install MicroK8s using Snap
Follow the [official installation instructions for MicroK8s](https://canonical.com/microk8s#install-microk8s).
* Make sure to use the `--classic` flag when installing.

### 3. Add /snap/bin to PATH
You may need to add MicroK8s to your PATH if `microk8s` is not available as a command:
```
echo 'export PATH=$PATH:/snap/bin' >> ~/.bashrc
source ~/.bashrc
```

### 4. Configure Roles and Permissions
You may need to add yourself to the microk8s group:
```
sudo usermod -a -G microk8s $USER && sudo newgrp microk8s
```
* To exit the root session, type `exit`.

Check if you can now access MicroK8s:
```
microk8s status --wait-ready
```

### 5. Enable Recommended Addons
Enable the following addons:
```
microk8s enable dashboard ingress hostpath-storage metrics-server
```

### 6. Export Kube Config
Run this to ensure that `.kube/` is present and in the home directory with proper permissions:
```
mkdir -p ~/.kube && chmod 0700 ~/.kube
```
Export MicroK8s config to `.kube/` for Helm:
```
microk8s kubectl config view --raw > ~/.kube/config
```

### Accessing the Cluster using kubectl
MicroK8s uses `microk8s kubectl` for accessing the cluster. Life is too short for that, so add an alias:
```
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc && source ~/.bashrc
```
or even just `k`:
```
echo "alias k='microk8s kubectl'" >> ~/.bashrc && source ~/.bashrc
```

---

## Minikube
**For testing and developing locally**

### 1. Installation
1. Follow the [Minikube Installation Instructions](https://minikube.sigs.k8s.io/docs/start/)
2. Enable the required ingress addon:
```
minikube addons enable ingress
```

### 2. Installing the FLAME Hub
See [Install FLAME Hub Chart](3_install_flame_hub_chart.md).

### 3. Accessing Your Deployments
The default FLAME Hub chart uses ingress to expose the Hub and Harbor.
You can verify the ingress resources and IP by running:
```
kubectl get ingress
```
* See also: [Quick start guide on accessing your deployments (Minikube docs)](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download#Ingress)

#### Linux and macOS
You can access the ingress at the IP printed in the output.

> **Note for Docker Desktop Users:**
>
> To get ingress to work, open a new terminal window and run `minikube tunnel`, then use `127.0.0.1` in place of `<ip>` in the following step.

To get the ingress-controller to recognize which service you want to access, use the hostnames you configured.
On the machine you want to use to access the WebUI, edit the hosts file:
```
sudo nano /etc/hosts
```
Add the lines:
```
<hub hostname> <ip>
# optionally add also harbor
<harbor hostname> <ip>
```
Access your Hub at `https://<hub hostname>`.

#### Windows
Use the helper script in `scripts/`:
```shell
cd scripts
```

Open PowerShell as Administrator:
```shell
powershell -ExecutionPolicy Bypass -File .\minikube-dns.ps1 <hubURL> <harborURL>
```

---

## Helm
Follow the [Helm Installation Instructions](https://helm.sh/docs/intro/install/).

---

## Next Steps

Once your Kubernetes cluster is running:

1. **(Optional)** Set up storage replication across multiple nodes — see [2: Storage Replication](2_setup_storage_replication.md).
2. Install the FLAME Hub Helm chart — see [3: Install FLAME Hub Chart](3_install_flame_hub_chart.md).
