#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"
write_line="$script_dir/../helper-scripts/write-text-line-in-file.sh"

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

if [ ! -f "$write_line" ]; then
    log_error "write_line_in_file helper not found at: $write_line"
    exit 1
fi

# =========================
# Proton VPN installation
# =========================

log_info "Installing Proton VPN dependencies..."
$apt_get_install wget gpg apt-transport-https ca-certificates

KEYRING_PATH="/usr/share/keyrings/protonvpn-archive-keyring.gpg"
REPO_LIST="/etc/apt/sources.list.d/protonvpn.list"

if [ ! -f "$KEYRING_PATH" ]; then
    log_info "Adding Proton VPN GPG key..."
    wget -qO- https://repo.protonvpn.com/debian/public_key.asc \
        | gpg --dearmor \
        | sudo tee "$KEYRING_PATH" > /dev/null
else
    log_info "Proton VPN GPG key already present"
fi

if [ ! -f "$REPO_LIST" ]; then
    log_info "Adding Proton VPN APT repository..."
    echo "deb [signed-by=$KEYRING_PATH] https://repo.protonvpn.com/debian stable main" \
        | sudo tee "$REPO_LIST" > /dev/null
else
    log_info "Proton VPN APT repository already present"
fi

log_info "Updating APT metadata..."
sudo apt update

log_info "Installing Proton VPN desktop client..."
$apt_get_install proton-vpn-gnome-desktop

# =========================
# Post-install notes
# =========================

log_info "Proton VPN installation complete."
log_info "Launch the app with: protonvpn-app"
log_info "You must sign in with your Proton account on first launch."

