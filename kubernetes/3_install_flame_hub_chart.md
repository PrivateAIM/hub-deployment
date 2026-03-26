# 3 — Install FLAME Hub Chart

> **Part 3 of 3** — [1: K8s Node Setup](1_setup_kubernetes_nodes.md) · [2: Storage Replication](2_setup_storage_replication.md)

The FLAME Hub Chart provides a default configuration in `values.yaml` but is meant to be installed with your own adjusted override values file, e.g. `values_local.yaml`.
To get an overview of all configuration options, see the [`values.yaml` in the Helm Repository](https://github.com/PrivateAIM/helm/blob/master/charts/flame-hub/values.yaml).
You can choose if you want to use the chart's harbor or a separate external harbor instance.

## Prerequisites
* Existing k8s distribution (see [1: K8s Node Setup](1_setup_kubernetes_nodes.md) for a guide)
  * Ingress addon
  * Default StorageClass (e.g. hostpath-storage addon in MicroK8s)
* Two domain names (one for the Hub, one for Harbor). If you run the Hub on your local machine, you can choose them freely and set them in your hosts file (`/etc/hosts`)

## Storage
The chart will use whichever storage class is the default in your cluster, unless you specify otherwise in the values. See `/charts/third-party/openebs` for instructions how to setup Mayastor Storage Replication. This requires 3+ nodes in your cluster and will replicate persistant volumes accross them.

## Ingress
See the `values.yaml` for ingress options. The default ingress configuration will use path-based routing for all services except Harbor (which requires its own hostname). You will have to provide an extra (sub)domain if you want to use the harbor component of this chart. The current setup does not automatically acquire TLS certificates.

## Gateway API
Gateway API is the newer alternative to ingress. The FLAME Hub has been tested with the F5 NGINX Gateway Fabric. To be able to upload large files and log into the UI, custom nginx configuration is generally required. When using Ingress, this is done via annotations. Gateway API theoretically also supports this, but NGINX Gateway Fabric (NGF) requires extra resources called "snippets". The FLAME-Hub charts provides these snippets, so all you have to do is set the `snippets` field to `true` in the values. For this reason it is strongly suggested to use F5 NGF.
You can install it into your cluster using:
```bash
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  -n nginx-gateway \
  --set nginxGateway.snippets.enable=true \
  --set nginx.kind=daemonSet \
  --set nginx.service.type=NodePort \
  --set nginx.service.externalTrafficPolicy=Local \
  --set-json 'nginx.service.nodePorts=[{"port":31437,"listenerPort":80}, {"port":30478,"listenerPort":8443}]'
```
Note: This will expose the Hub on all k8s nodes at port 31437, so configure your public facing proxy/loadbalancer accordingly.
## Installing the FLAME Hub Chart

### 1. Option: Official Chart Repo
```bash
helm repo add flame https://PrivateAIM.github.io/helm
helm repo update
```
Create your custom values file (see the [chart's README](https://github.com/PrivateAIM/helm/tree/master/charts/flame-hub))
```bash
helm install <release-name> -f <values-file> flame/hub
```

### 2. Option: Chart Source Code
> Choose this option if you want to
>
> a) modify not only the chart values, but also the chart files.
>
> b) run the newest, not yet released version of the chart.
```bash
git clone https://github.com/PrivateAIM/helm.git
cd helm
```

```bash
cd charts/flame-hub
```
Create your custom values file or copy the suggested minimal example.


```bash
cp values_min.yaml <my-custom-values-file>
```
Install the Chart with the custom values file.
> **Storage Replication (optional)** see the comments regarding mayastor in `values.yaml` on how to configure your values file for storage replication

```bash
helm install <release name> -f <my-custom-values-file> .
```
For further instructions see the [chart's README](https://github.com/PrivateAIM/helm/tree/master/charts/flame-hub) 
## Accessing the hub
For accessing the hub in a Minikube installation, refer to the [Minikube Setup: Accessing Deployments](1_setup_kubernetes_nodes.md#3-accessing-your-deployments)
