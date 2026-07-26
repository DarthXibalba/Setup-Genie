#!/usr/bin/env bash
set -Eeuo pipefail

# Remove the native APT-installed Proton VPN clients, their now-unused
# dependencies, Proton's APT repository, and Proton-created NetworkManager
# kill-switch profiles. This intentionally leaves user data in ~/.config and
# ~/.cache alone.

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

assume_yes=false
if [ "${1:-}" = "--yes" ]; then
    assume_yes=true
elif [ "$#" -ne 0 ]; then
    log_error "Usage: $0 [--yes]"
    exit 2
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
    log_error "This script requires an Ubuntu or Debian system with APT."
    exit 1
fi

# Match Proton VPN packages without explicitly purging generic Python
# libraries. APT autoremove will remove dependencies only when nothing else
# installed needs them.
proton_packages=()
while IFS=$'\t' read -r package status; do
    package_without_arch="${package%%:*}"
    if [[ "$status" == "ii "* ]] &&
       [[ "$package_without_arch" =~ ^(proton-vpn($|-)|protonvpn($|-)|python3-proton-vpn($|-)|python3-protonvpn-nm-lib$) ]]; then
        proton_packages+=("$package")
    fi
done < <(dpkg-query -W -f='${binary:Package}\t${db:Status-Abbrev}\n' 2>/dev/null || true)

proton_connections=()
if command -v nmcli >/dev/null 2>&1; then
    while IFS= read -r connection_name; do
        if [[ "$connection_name" == pvpn-* ]]; then
            proton_connections+=("$connection_name")
        fi
    done < <(nmcli --terse --escape no --fields NAME connection show 2>/dev/null || true)
fi

repo_files=(
    /etc/apt/sources.list.d/protonvpn.list
    /etc/apt/sources.list.d/protonvpn-stable.list
    /etc/apt/sources.list.d/protonvpn-stable.sources
    /etc/apt/sources.list.d/protonvpn-beta.list
    /etc/apt/sources.list.d/protonvpn-beta.sources
)

keyring_files=(
    /usr/share/keyrings/protonvpn-archive-keyring.gpg
    /usr/share/keyrings/protonvpn-stable-archive-keyring.gpg
    /usr/share/keyrings/protonvpn-beta-archive-keyring.gpg
)

repo_artifacts=()
for path in "${repo_files[@]}" "${keyring_files[@]}"; do
    if [ -e "$path" ] || [ -L "$path" ]; then
        repo_artifacts+=("$path")
    fi
done

if [ "${#proton_packages[@]}" -eq 0 ] &&
   [ "${#proton_connections[@]}" -eq 0 ] &&
   [ "${#repo_artifacts[@]}" -eq 0 ]; then
    log_success "No native APT-installed Proton VPN components were found."
    exit 0
fi

log_info "The following Proton VPN components were found:"
if [ "${#proton_packages[@]}" -gt 0 ]; then
    printf '  Packages:\n'
    printf '    %s\n' "${proton_packages[@]}"
fi
if [ "${#proton_connections[@]}" -gt 0 ]; then
    printf '  NetworkManager profiles:\n'
    printf '    %s\n' "${proton_connections[@]}"
fi
if [ "${#repo_artifacts[@]}" -gt 0 ]; then
    printf '  APT repository files:\n'
    printf '    %s\n' "${repo_artifacts[@]}"
fi

if [ "${#proton_packages[@]}" -gt 0 ]; then
    log_info "APT removal preview (APT may also list unused dependencies):"
    sudo apt-get --simulate autoremove --purge "${proton_packages[@]}"
fi

log_warn "Continuing may disconnect an active Proton VPN session."
if ! $assume_yes; then
    read -r -p "Remove the components listed above? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        log_info "Cancelled; no changes were made."
        exit 0
    fi
fi

# Remove kill-switch and leak-protection profiles first so they cannot leave
# networking blocked after the application is gone.
for connection_name in "${proton_connections[@]}"; do
    log_info "Deleting NetworkManager profile: $connection_name"
    if ! sudo nmcli connection delete "$connection_name"; then
        log_warn "Could not delete NetworkManager profile: $connection_name"
    fi
done

if [ "${#proton_packages[@]}" -gt 0 ]; then
    log_info "Purging Proton VPN packages and dependencies no longer in use..."
    apt_args=(autoremove --purge)
    if $assume_yes; then
        apt_args+=(-y)
    fi
    sudo apt-get "${apt_args[@]}" "${proton_packages[@]}"
fi

if [ "${#repo_artifacts[@]}" -gt 0 ]; then
    log_info "Removing Proton VPN APT repository files..."
    sudo rm -f -- "${repo_artifacts[@]}"
fi

log_success "Native Proton VPN removal is complete."
log_info "Personal settings and logs were preserved under ~/.config/Proton and ~/.cache/Proton."
log_info "Before a release upgrade, run: sudo apt update && sudo apt full-upgrade"
