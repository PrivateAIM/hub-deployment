
#!/bin/bash

set -e 
set -u 

MK8S="/snap/bin/microk8s"

confirm_step() {
    local step_label="$1"
    read -rp "Run ${step_label}? [y/N]: " RUN_STEP
    if [[ "${RUN_STEP:-}" =~ ^[Yy]$ ]]; then
        return 0
    fi
    echo "[SKIP] ${step_label}"
    return 1
}

echo "Starting MicroK8s Installation..."

DEFAULT_SNAP_COMMON_PATH="/mnt/vdb1"
SNAP_COMMON_PATH="$DEFAULT_SNAP_COMMON_PATH"

if confirm_step "Step 1: Configure custom storage volume"; then
    read -rp "Enter path for snap common (default: $DEFAULT_SNAP_COMMON_PATH): " SNAP_COMMON_PATH
    if [ -z "${SNAP_COMMON_PATH}" ]; then
        SNAP_COMMON_PATH="$DEFAULT_SNAP_COMMON_PATH"
    fi

    if [ ! -d "$SNAP_COMMON_PATH" ]; then
        echo "[ERROR] Mount point $SNAP_COMMON_PATH does not exist."
        exit 1
    fi

    sudo mkdir -p /var/snap/microk8s/common "$SNAP_COMMON_PATH/microk8s/common"

    if ! mountpoint -q /var/snap/microk8s/common; then
        echo "Applying bind mount..."
        sudo mount --bind "$SNAP_COMMON_PATH/microk8s/common" /var/snap/microk8s/common
    fi

    if ! grep -q "/var/snap/microk8s/common" /etc/fstab; then
        echo "$SNAP_COMMON_PATH/microk8s/common /var/snap/microk8s/common none bind 0 0" | sudo tee -a /etc/fstab
    else
        echo "A mount point for /var/snap/microk8s/common already exists in /etc/fstab."
    fi
    echo "[SUCCESS] Storage configured."
fi

if confirm_step "Step 2: Installing Snapd and MicroK8s"; then
    sudo apt update -qq && sudo apt install -y snapd

    DEFAULT_CHANNEL="1.32"
    read -rp "Optional: Specify MicroK8s channel [default: $DEFAULT_CHANNEL]: " MICROK8S_CHANNEL
    MICROK8S_CHANNEL="${MICROK8S_CHANNEL:-$DEFAULT_CHANNEL}"

    sudo snap install microk8s --classic --channel="${MICROK8S_CHANNEL}"

    # Explicitly update the path for this subshell session
    export PATH=$PATH:/snap/bin
    echo "[SUCCESS] Installation complete. Current Path: $PATH"
fi

if confirm_step "Step 3: Configuring Permissions"; then
    sudo usermod -a -G microk8s "$USER"
    sudo chown -f -R "$USER" "$HOME/.kube" || true
fi

if confirm_step "Step 4: Enable recommended addons"; then
    # Using the absolute path to avoid "command not found"
    sudo "$MK8S" status --wait-ready

    echo "Enabling Addons..."
    for addon in dashboard ingress hostpath-storage metrics-server; do
        echo "Enabling $addon..."
        if sudo "$MK8S" enable "$addon"; then
            echo "[SUCCESS] $addon enabled."
        else
            echo "[WARNING] Failed to enable $addon, continuing..."
        fi
    done
    echo "[SUCCESS] Addon enabling complete."
fi

if confirm_step "Step 5: Exporting Kubeconfig"; then
    mkdir -p "$HOME/.kube"
    sudo "$MK8S" kubectl config view --raw | sudo tee "$HOME/.kube/config" > /dev/null
    sudo chmod 600 "$HOME/.kube/config"
    sudo chown "$USER:$USER" "$HOME/.kube/config"
    echo "[SUCCESS] Kubeconfig exported."
fi

if confirm_step "Step 6: Persisting /snap/bin in PATH"; then
    if ! grep -q "/snap/bin" "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:/snap/bin' >> "$HOME/.bashrc"
    fi
fi

echo "Installation complete."