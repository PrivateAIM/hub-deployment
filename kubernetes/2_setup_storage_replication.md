# 2 — Storage Replication (OpenEBS/Mayastor) (optional)
**For multi-node production deployments**

> **Part 2 of 3** — [1: K8s Node Setup](1_setup_kubernetes_nodes.md) · [3: Install FLAME Hub Chart](3_install_flame_hub_chart.md)

OpenEBS is a chart that provides extra storage options. We will be using Mayastor Replicated Storage to synchronize Persistent Volumes across multiple nodes in the cluster. This aims to ensure no data is lost when a node fails. With extra configuration, it enables automatic failover.

## Node Setup
Before installing OpenEBS, you must prepare the k8s nodes you want to use for Mayastor.

### Automatic Script 🤖
Use the `2_prepare_for_mayastor.sh` script in `scripts/`.
> The script has been tested on Debian.
>
> The script can safely be run multiple times.
```
sudo ./scripts/2_prepare_for_mayastor.sh
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
4. Follow the installation instructions of the [chart's README](https://github.com/PrivateAIM/helm/tree/master/charts/third-party/openebs#readme)
5. For the following installation of the FLAME Hub Helm chart, remember to configure the `mayastor-replicated` storage class for stateful services. See example comments in `charts/flame-hub/values.yaml` (search for mayastor)

## Rebooting Nodes When Using Replicated Storage
Install one of these plugins for kubectl first:
- [kubectl openebs plugin](https://openebs.io/docs/user-guides/kubectl-openebs)
- [kubectl mayastor plugin](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/advanced-operations/kubectl-plugin)

Notes:
- `<namespace>` is the OpenEBS namespace (usually `openebs`).
- `reboot-cordon` and `reboot-drain` are arbitrary labels for this operation.
- List available nodes with `kubectl get nodes`.

1. **Mark the node as cordoned in Mayastor**
```
kubectl mayastor cordon node -n <namespace> <node_name> reboot-cordon
```
2. **Verify the Mayastor cordon state**
```
kubectl mayastor get cordon nodes -n <namespace>
```
3. **Mark the node as drained in Mayastor**
```
kubectl mayastor drain node -n <namespace> <node_name> reboot-drain
```
4. **Verify the Mayastor drain state**
```
kubectl mayastor get drain nodes -n <namespace>
```
5. **Drain Kubernetes workloads from the node**
```
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
```
6. **Reboot the node**
```
reboot
```
7. **Allow Kubernetes scheduling on the node again**
```
kubectl uncordon <node-name>
```
8. **Remove the Mayastor cordon markers**
```
kubectl mayastor uncordon node <node_name> reboot-cordon -n <namespace>
```
```
kubectl mayastor uncordon node <node_name> reboot-drain -n <namespace>
```
9. **Confirm volumes are healthy after reboot**
```
kubectl mayastor get volumes -n openebs
```

## Upgrading the OpenEBS chart
1. **Trigger the Helm upgrade**
2. **If the upgrade succeeds, you are good to go. However, the upgrade will likely be pending indefinitely because io-engine pods need to be replaced manually. In that case, proceed with steps 3 etc.**
3. **Drain a node**
```
kubectl mayastor drain node -n <namespace> <node_name> upgrade
```
4. **Delete the io pod on that node**
```
kubectl delete pod -n <namespace> openebs-io-engine-12345 # the pod running on the node you drained
```
5. **Uncordon Node**
```
kubectl mayastor uncordon node <node_name> upgrade -n <namespace>
```
6. **Verify Volumes are "online" with**
```
kubectl mayastor get volumes -n openebs
```
7. **Repeat with the rest of your nodes** 
