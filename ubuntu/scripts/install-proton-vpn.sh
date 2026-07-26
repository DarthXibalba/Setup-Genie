#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/../helper-scripts/logging.sh"
snap_install="$script_dir/../helper-scripts/snap-install.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

if [ ! -f "$snap_install" ]; then
    log_error "Snap install helper not found at: $snap_install"
    exit 1
fi

# =========================
# Proton VPN installation
# =========================

# Refuse to layer the Snap over an existing native APT installation. Leaving
# those packages installed would preserve the system-Python dependencies that
# this installation method is intended to avoid.
native_packages=()
while IFS=$'\t' read -r package status; do
    package_without_arch="${package%%:*}"
    if [[ "$status" == "ii "* ]] &&
       [[ "$package_without_arch" =~ ^(proton-vpn($|-)|protonvpn($|-)|python3-proton-vpn($|-)|python3-protonvpn-nm-lib$) ]]; then
        native_packages+=("$package")
    fi
done < <(dpkg-query -W -f='${binary:Package}\t${db:Status-Abbrev}\n' 2>/dev/null || true)

if [ "${#native_packages[@]}" -gt 0 ]; then
    log_error "Native APT-installed Proton VPN packages are still present:"
    printf '  %s\n' "${native_packages[@]}"
    log_info "Remove them first with: $script_dir/remove-proton-vpn.sh"
    exit 1
fi

log_info "Installing the confined Proton VPN Snap..."
"$snap_install" proton-vpn

# =========================
# Post-install notes
# =========================

log_success "Proton VPN installation complete."
log_info "Launch Proton VPN from the desktop application menu."
log_info "You must sign in with your Proton account on first launch."
log_warn "The Snap sandbox does not support every feature available in Proton's native APT app."
