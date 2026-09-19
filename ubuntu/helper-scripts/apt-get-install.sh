#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

# =========================
# Validate args
# =========================

if [ $# -eq 0 ]; then
    log_error "No packages specified."
    log_info  "This script installs whatever packages are specified as command arguments."
    log_info  "Usage: $0 <package_name1> <package_name2> ..."
    exit 1
fi

# =========================
# Install packages
# =========================

missing_packages=()
for package_name in "$@"; do
    if [ "$(dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null)" != "install ok installed" ]; then
        missing_packages+=("$package_name")
    else
        log_info "$package_name is already installed. Skipping."
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    log_step "Installing ${missing_packages[*]}..."
    sudo apt-get update -qq
    sudo apt-get install -y "${missing_packages[@]}"
    log_success "Packages installed: ${missing_packages[*]}"
fi
