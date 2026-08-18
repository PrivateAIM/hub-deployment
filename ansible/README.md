# Debian 13 MicroK8s

Installs and configures an independent MicroK8s host. Requires Ansible Core 2.15+, SSH access, and
passwordless `sudo` (or `--ask-become-pass`) on the Debian 13 targets.

## Inventory

```bash
cp inventory/hosts.example.yml inventory/hosts.yml
```

Shared variables belong under `microk8s_hosts.vars`; host-specific values can be set below each
host. Important variables:

```yaml
microk8s_channel: 1.36/stable
microk8s_snap_data_device: /dev/vdb
microk8s_snap_data_path: /mnt/microk8s
microk8s_users:
  - debian
```

`microk8s_snap_data_device` is required and must be a dedicated block device. If it has no
filesystem, the role formats it as ext4. Existing filesystems are preserved. Devices with child
partitions or unexpected mounts are rejected.

## Install MicroK8s

```bash
ansible-playbook -i inventory/hosts.yml microk8s.yml --check --diff
ansible-playbook -i inventory/hosts.yml microk8s.yml --diff
```

Reconnect after the run so new `microk8s` group membership takes effect.

## Upgrade Debian

```bash
ansible-playbook -i inventory/hosts.yml upgrade.yml --diff
```

This upgrades packages and reports whether a reboot is required. It does not drain or reboot
hosts.
