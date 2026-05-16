#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

if [ ! -f "$apt_get_install" ]; then
    log_error "apt-get helper not found at: $apt_get_install"
    exit 1
fi

# =========================
# nerdctl full bundle install
# =========================

nerdctl_version="2.2.2"
nerdctl_file="nerdctl-full-${nerdctl_version}-linux-amd64.tar.gz"
nerdctl_url="https://github.com/containerd/nerdctl/releases/download/v${nerdctl_version}/${nerdctl_file}"
nerdctl_tmp="/tmp/${nerdctl_file}"

if nerdctl --version 2>/dev/null | grep -q "nerdctl version ${nerdctl_version}"; then
    log_info "nerdctl v${nerdctl_version} already installed. Skipping."
    exit 0
fi

log_info "Installing prerequisites..."
$apt_get_install iptables uidmap fuse-overlayfs

log_info "Downloading nerdctl full bundle v${nerdctl_version}..."
if [ ! -f "$nerdctl_tmp" ]; then
    wget -q "$nerdctl_url" -O "$nerdctl_tmp"
fi

log_info "Extracting to /usr/local..."
sudo tar -C /usr/local -xzf "$nerdctl_tmp"

rm -f "$nerdctl_tmp"

# =========================
# systemd services
# =========================

log_info "Enabling and starting containerd.service..."
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd

if sudo systemctl is-active --quiet containerd; then
    log_success "containerd.service is running."
else
    log_error "containerd.service failed to start. Check: sudo journalctl -u containerd"
    exit 1
fi

log_info "Enabling buildkit.service (not starting by default)..."
sudo systemctl enable buildkit
log_info "Start buildkit manually when needed: sudo systemctl start buildkit"

# =========================
# Done
# =========================

log_success "nerdctl v${nerdctl_version} (full bundle) installed successfully."
log_info "Verify: nerdctl --version"
log_info "Test:   sudo nerdctl info"
