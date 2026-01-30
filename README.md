# Hub Deployment ☁️

This repository contains instructions on how to deploy the HUB ecosystem.

> 🚧 **Work in Progress**
>
> The HUB deployment document is currently under active development and is not yet ready.


## Kubernetes

...

## Docker-Compose

Basic configuration occurs via environment variables in an `.env` file.
An example (`.env.example`) is provided in the repository.

| Variable        | Mandatory | Use/Meaning                                                       |
|-----------------|:---------:|-------------------------------------------------------------------|
| `HUB_IMAGE`     |     ❌     | Used to override the default image for the `HUB` docker image     |
| `HUB_IMAGE_TAG` |     ❌     | Used to override the default image tag for the `HUB` docker image |
| `SUBNET`        |     ❌     | Used to change the default docker subent.                         |
