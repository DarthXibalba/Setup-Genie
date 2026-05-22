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

for package_name in "$@"; do
    if ! command -v "$package_name" &>/dev/null; then
        log_step "Installing $package_name..."
        sudo apt-get update -qq
        sudo apt-get install "$package_name" -y
        log_success "$package_name installed."
    else
        log_info "$package_name is already installed. Skipping."
    fi
done
