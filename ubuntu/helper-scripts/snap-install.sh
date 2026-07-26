#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/apt-get-install.sh"
logging_file="$script_dir/logging.sh"

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
# Validate args
# =========================

classic=false
channel=""
package_names=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --classic)
            classic=true
            ;;
        --channel)
            if [ "$#" -lt 2 ]; then
                log_error "--channel requires a value."
                exit 2
            fi
            channel="$2"
            shift
            ;;
        --channel=*)
            channel="${1#*=}"
            ;;
        --help|-h)
            log_info "Usage: $0 [--classic] [--channel <channel>] <snap_name1> <snap_name2> ..."
            exit 0
            ;;
        -*)
            log_error "Unsupported option: $1"
            log_info "Usage: $0 [--classic] [--channel <channel>] <snap_name1> <snap_name2> ..."
            exit 2
            ;;
        *)
            package_names+=("$1")
            ;;
    esac
    shift
done

if [ "${#package_names[@]}" -eq 0 ]; then
    log_error "No snap packages specified."
    log_info "Usage: $0 [--classic] [--channel <channel>] <snap_name1> <snap_name2> ..."
    exit 1
fi

# =========================
# Ensure Snap is available
# =========================

if ! command -v snap >/dev/null 2>&1; then
    log_step "Snap is not installed. Installing snapd..."
    "$apt_get_install" snapd
fi

if ! command -v snap >/dev/null 2>&1; then
    log_error "The snap command is unavailable after installing snapd."
    exit 1
fi

# =========================
# Install packages
# =========================

snap_options=()
if $classic; then
    snap_options+=(--classic)
fi
if [ -n "$channel" ]; then
    snap_options+=("--channel=$channel")
fi

for package_name in "${package_names[@]}"; do
    if snap list "$package_name" >/dev/null 2>&1; then
        log_info "$package_name is already installed. Skipping."
        continue
    fi

    log_step "Installing Snap package $package_name..."
    sudo snap install "$package_name" "${snap_options[@]}"

    if snap list "$package_name" >/dev/null 2>&1; then
        log_success "$package_name installed."
    else
        log_error "$package_name was not found in the installed Snap packages."
        exit 1
    fi
done
