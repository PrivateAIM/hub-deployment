# FLAME Hub Helm Chart
The FLAME Hub Chart provides a default configuration in `values.yaml` but is meant to be installed with your own adjusted override values file, e.g. `values_local.yaml`.
To get an overview of all configuration options, see the [`values.yaml` in the Helm Repository](https://github.com/PrivateAIM/helm/blob/master/charts/flame-hub/values.yaml)
You can choose if you want to use the chart's harbor or a seperate external harbor instance.

## Prerequisites:
* Existing k8s distribution (see [`node-setup.md`](node-setup.md) for a guide)
  * Ingress addon
  * Default StorageClass (e.g. hostpath-storage addon in micrko8s)
* Two domain names (one for the Hub, one for Harbor). If you run the Hub on your local machine, you can choose them freely and set them in your hosts file  (`/etc/hosts`)

## Storage
The chart will use whichever storage class is the default in your cluster, unless you specify otherwise in the values. See `/charts/third-party/openebs` for instructions how to setup Mayastor Storage Replication. This requires 3+ nodes in your cluster and will replicate persistant volumes accross them.

## Ingress
See the `values.yaml` for ingress options. The default ingress configuration will use path-based routing for all services except Harbor (which requires its own hostname). You will have to provide an extra (sub)domain if you want to use the harbor component of this chart. The current setup does not automatically acquire TLS certificates.

## Installing the FLAME Hub Chart

### 1. Option: Official Chart Repo
```
helm repo add flame https://PrivateAIM.github.io/helm
helm repo update
```
Create your custom values file (instructions below).
```
helm install <release-name> -f <values-file> flame/hub
```

### 2. Option: Chart Source Code
> Choose this option if you want to
>
> a) modify not only the chart values, but also the chart files.
>
> b) run the newest, not yet released version of the chart.
```
git clone https://github.com/PrivateAIM/helm.git
cd helm
```

```
cd charts/flame-hub
```
Create your custom values file (instructions below).

```
helm install <release name> -f <values-file> .
```

## Minimal configuration using custom values file

This is the values-file mentioned in the sections above. Call it `override_values.yaml` or whatever you want.

```
global:
  flameHub:
    ingress:
      enabled: true
      ssl: true
      hostname: "hub.local"

grafana:
  # disable plugins until plugin issues are fixed
  plugins:

harbor:
  enabled: true
  externalURL: "https://harbor.hub.local/" # don't forget https://

```

## Minimal Configuration using 3 nodes and Mayastor
Before continuing, make sure OpenEBS is installed in your cluster and the "mayastor-replicated" storageClass exists.
For a suggested setup, see [`mayastor-instructions.md`](mayastor-instructions.md)

```
global:
  flameHub:
    ingress:
      enabled: true
      ssl: true
      hostname: "hub.local"

minio:
  persistence:
    storageClass: "mayastor-replicated"

rabbitmq:
  persistence:
    storageClass: "mayastor-replicated"

grafana:
  # disable plugins until plugin issues are fixed
  plugins:
  persistence:
    storageClass: "mayastor-replicated"

harbor:
  enabled: true
  externalURL: "https://harbor.hub.local/" # don't forget https://
  persistence:
    persistentVolumeClaim:
      registry:
        storageClass: "mayastor-replicated"

```

## Accessing the hub
For accessing the hub in a minikube installation, refer to the [Minikube Setup: Accessing Deployments](node-setup.md#accessing-your-deployments)
