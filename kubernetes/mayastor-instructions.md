# OpenEBS/Mayastor for FLAME
OpenEBS is a chart that provides extra storage options. We will be using Mayastor Replicated Storage to synchronize Persistant Volumes across multiple nodes in the cluster. This aims to ensure no data is lost when a node fails. With extra configuration, it enables automatic failover.

## Node Setup
Before installing OpenEBS, you must prepare the k8s nodes you want to use for mayastor.

### Automatic script 🤖
Use `prepare_for_mayastor.sh` script in `scripts/`.
> The script has been tested in Debian.
>
> The script can safely be run multiple times.
```
sudo ./scripts/prepare_for_mayastor.sh
```

Alternatively, you can manually do the following:
### 1. Configure hugepages
Enable hugepages:
```
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
```
Persist hugepages and apply:
```
echo "vm.nr_hugepages = 1024" > /etc/sysctl.d/20-microk8s-hugepages.conf
sysctl --system
```
### 2. Load NVMe-oF module
Load the module immediately:
```
modprobe nvme-tcp
```
Persist the module across reboots:
   * If `/etc/modules-load.d/nvme-tcp.conf` does not exist or does not
     contain `nvme-tcp`, create it with:
```
echo "nvme-tcp" > /etc/modules-load.d/nvme-tcp.conf`
```
### 3. Verify
Check hugepages:
```
grep HugePages_Total /proc/meminfo`
```
Check the module is active:
```
lsmod | grep nvme_tcp`
```
### 4. Label the node for Mayastor
```
kubectl label node <node_name> openebs.io/engine=mayastor
```
## Installing OpenEBS

The FLAME Helm repository provides a [wrapper chart for OpenEBS](https://github.com/PrivateAIM/helm/blob/master/charts/third-party/openebs) with some suggested default values.
Installing this chart will add a new StorageClass to your cluster. You can tell workloads of the Flame Hub to use this StorageClass by specifying it in `flame-hub/values.yaml`. Usually, only stateful workloads (StatefulSets) need replicated storage.


1. **Clone the [Flame Helm Repository](https://github.com/PrivateAIM/helm/) and navigate to `charts/third-party/openebs`**
2. Make sure you have 3 nodes in your cluster.
3. Make sure you have read the previous section on node preparation for mayastor.
    * If not already labled, label your nodes:
`kubectl label node <node_name> openebs.io/engine=mayastor`
4. Clone `values.yaml` to `values_local.yaml`.
5. Fill in your kubelet path and populate the disk pools section with your unmounted drives.
6. Install the chart:

```
helm dependency update .
```
```
helm install openebs . --namespace openebs --create-namespace -f values_local.yaml
```

7. Verify disk pools and `mayastor` storage classes:
```
kubectl get diskpools -n openebs
```
Note: Disk Pools may need 1-5 minutes to be ready
```
kubectl get storageclasses
```
8. Edit your FLAME-Hub values-file to use the new StorageClass. A reinstall of the Hub will probably be required.