# Hub Deployment ☁️

This repository contains instructions on how to deploy the HUB ecosystem.

> 🚧 **Work in Progress**
>
> The HUB deployment document is currently under active development and is not yet ready.


## Kubernetes
### FLAME Hub Helm chart
**📜 See the [Kubernetes Instructions Page](kubernetes/kubernetes-instructions.md) for details and examples.**

The source code for the Helm chart is located in the [Helm repository](https://github.com/PrivateAIM/helm/tree/master/charts/flame-hub).
It can be installed in a k8s cluster using:
```
helm repo add flame https://PrivateAIM.github.io/helm
helm repo update
```
```
helm install <release-name> -f <values-file> flame/hub
```
> ‼️The Chart will need some minimal configuration to work properly. Read the [Kubernetes Instructions Page](kubernetes/kubernetes-instructions.md)

### Kubernetes Node Setup Instructions:
* **📜 [K8s Node Setup using MicroK8s or Minikube](kubernetes/kubernetes-instructions.md)**
* **📜 [Guide for setting up Mayastor Storage Replication](kubernetes/mayastor-instructions.md)**

## Docker Compose
**📜 See the [Docker Compose Instructions Page](docker-compose/docker-compose-instructions.md) for details and examples.**

A Docker Dompose file is provided in this repository.

As the `docker-compose.yaml` does not include the Harbor service, you must either provide the credentials to an existing Harbor or [install Harbor seperately](https://goharbor.io/docs/latest/install-config/). In most cases, a Kubernetes installation using Minikube will be quicker to set up.

Generally, the docker compose setup is only meant for testing and development.




