# K8s Node Setup for FLAME
Contents:
* MicroK8s
* Minikube
* Installing Helm

## MicroK8s on a debian-based system
### Automatic Installation script 🤖
Instead of following the below installation guide, you can also run the bash script:
> The script has been tested in Debian.

```
./scripts/microk8s_setup.sh
```
This script will optionally:
* Setup non default MicroK8s storage path (see section Storage)
* Install Snap and MicroK8s
* Configure roles and permissions
* Export Kubeconfig
* Add /snap/bin to PATH

### 1. Storage
If you want to use a non-default path for microk8s storage, it is recommended to set this up before installing microk8s.

With the hostpath-storage addon enabled, your cluster will provision Persistent Volumes using the default StorageClass `microk8s-hostpath`. This will use your SNAP_COMMON directory at `/var/snap/microk8s/common`.
If you want your PVs to be located in another location (maybe another drive), you can either:
a) create a new StorageClass and make it the default (however running microk8s in Snap restricts filesystem access)
b) just mount (or symlink) the SNAP_COMMON directory to your preferred destination.
```
sudo mount --bind /mnt/vdb1/microk8s/common /var/snap/microk8s/common

# for persistence
echo "/mnt/vdb1/microk8s/common /var/snap/microk8s/common none bind 0 0" | sudo tee -a /etc/fstab
```

### 2. Install microk8s using Snap
Follow the [official installation instructions for microk8s](https://canonical.com/microk8s#install-microk8s)
* Make sure to use the `--classic` flag when installing.

### 3. Add /snap/bin to PATH
You may need to add microk8s to your PATH if `microk8s` is not available as a command:
```
echo 'export PATH=$PATH:/snap/bin' >> ~/.bashrc
source ~/.bashrc
```
### 4. Configure roles and permissions

You may need to add yourself to the microk8s group:
```
sudo usermod -a -G microk8s $USER && sudo newgrp microk8s
```
* To exit the root session type `exit`.

Check if you can now access microk8s:
```
microk8s status --wait-ready
```
### 5. Enable recommended addons
Enable the following addons:
```
microk8s enable dashboard ingress hostpath-storage metrics-server
```
### 6. Export Kube Config
Run this to ensure that `.kube/` is present and in the home directory with proper permissions:
```
mkdir -p ~/.kube && chmod 0700 ~/.kube
```
Export microk8s config to .kube/ for helm
```
microk8s kubectl config view --raw > ~/.kube/config
```

### Accessing the cluster using kubectl
MicroK8s uses `microk8s kubectl` for accessing the cluster. Life is too short for that so add an alias `kubectl`:
```
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc && source ~/.bashrc
```
or even just `k`:
```
echo "alias k='microk8s kubectl'" >> ~/.bashrc && source ~/.bashrc
```


## Minikube
### Installation
1. Follow the [Minikube Installation Instructions](https://minikube.sigs.k8s.io/docs/start/)
2. Enable required addon: ingress
```
minikube addons enable ingress
```
### Installing the FLAME Hub
See [Hub Installation](kubernetes-instructions.md)

### Accessing your deployments:
The default FLAME Hub chart uses ingress to expose the Hub and the Harbor.
1. You can verify the ingress resources and IP by running
```
kubectl get ingress
```
You can access the ingress at the IP printed in the output.
To get the ingress-controller to recognize, which service you want to access, you need to use the hostnames you configured.

2. On the machine you want to use to access the WebUI, edit hosts file:
```
sudo nano /etc/hosts
```
Add the lines
```
<hub hostname> <ip>
# optionally add also harbor
<harbor hostname> <ip>
```
3. Access your Hub at https://<hub hostname>

Note also: [Quick start guide on Accessing your deployments in the Minikube Documentation](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download#Ingress)

## Helm
Follow the [Helm Installation Instructions](https://helm.sh/docs/intro/install/)

