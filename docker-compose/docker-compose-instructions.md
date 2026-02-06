# FLAME Hub Docker Compose

This Setup guide does not include the Harbor service, you must either provide the credentials to an existing Harbor or [install Harbor seperately](https://goharbor.io/docs/latest/install-config/).

## Configuration
Basic configuration occurs via environment variables in an `.env` file.
An example (`.env.example`) is provided in the repository.

| Variable        | Mandatory | Use/Meaning                                                       |
|-----------------|:---------:|-------------------------------------------------------------------|
| `HUB_IMAGE`     |     ❌     | Used to override the default image for the `HUB` docker image     |
| `HUB_IMAGE_TAG` |     ❌     | Used to override the default image tag for the `HUB` docker image |
| `SUBNET`        |     ❌     | Used to change the default docker subent.                         |

‼️ To provide credentials to Harbor (either local or external), use the following Variable:

| Variable        | Mandatory | Use/Meaning                                                       |
|-----------------|:---------:|-------------------------------------------------------------------|
| `HARBOR_URL`     |     ✅     | Construct using `<username>:<passwd>@<harbor_host>` (no `https://` ) |

## Run

Run using:
```
docker compose up -d
```

