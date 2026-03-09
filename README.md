# Hub Deployment ☁️

This repository contains instructions on how to deploy the HUB ecosystem.

> 🚧 **Work in Progress**
>
> The HUB deployment document is currently under active development and is not yet ready.


## Kubernetes

The source code for the Helm chart is located in the [Helm repository](https://github.com/PrivateAIM/helm/tree/master/charts/flame-hub).

### Guides

Follow these guides in order:

1. **📜 [K8s Node Setup](kubernetes/1_setup_kubernetes_nodes.md)** — MicroK8s / Minikube installation & configuration
2. **📜 [Storage Replication](kubernetes/2_setup_storage_replication.md)** — OpenEBS / Mayastor setup *(optional, for multi-node clusters)*
3. **📜 [Install FLAME Hub Chart](kubernetes/3_install_flame_hub_chart.md)** — Helm chart installation & configuration

### Quick Install

```
helm repo add flame https://PrivateAIM.github.io/helm
helm repo update
```
```
helm install <release-name> -f <values-file> flame/hub
```
> ‼️ The chart needs minimal configuration to work properly. See [Install FLAME Hub Chart](kubernetes/3_install_flame_hub_chart.md) for details.

## Docker Compose
**📜 See the [Docker Compose Instructions Page](docker-compose/docker-compose-instructions.md) for details and examples.**

A Docker Dompose file is provided in this repository.

As the `docker-compose.yaml` does not include the Harbor service, you must either provide the credentials to an existing Harbor or [install Harbor seperately](https://goharbor.io/docs/latest/install-config/). In most cases, a Kubernetes installation using Minikube will be quicker to set up.

Generally, the docker compose setup is only meant for testing and development.




