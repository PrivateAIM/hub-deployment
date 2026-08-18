# FLAME Hub deployment artifacts

This repository contains helper scripts and runnable configuration artifacts for standalone FLAME
Hub deployments.

All setup and operating instructions are maintained in the canonical
[FLAME deployment documentation](https://docs.privateaim.net/guide/deployment/). The source for
those guides is in the
[`PrivateAIM/documentation` repository](https://github.com/PrivateAIM/documentation/tree/master/src/guide/deployment).

The FLAME Helm charts and their value reference are maintained in
[`PrivateAIM/helm`](https://github.com/PrivateAIM/helm).

## Ansible Role for Microk8s nodes

Use the [`ansible/`](ansible/) playbooks to prepare one or more standalone MicroK8s hosts over SSH
and perform Debian package upgrades. See the Ansible README for inventory and execution commands.
