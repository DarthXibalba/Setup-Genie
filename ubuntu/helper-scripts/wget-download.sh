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

if [ $# -ne 2 ]; then
    log_error "Expected 2 arguments, got $#."
    log_info  "This script downloads (via wget) the first argument (argURL) to the second argument (argPath)."
    log_info  "Usage: $0 <argURL> <argPath>"
    exit 1
fi

argURL="$1"
argPath="$2"

# =========================
# Download file
# =========================

if [ ! -f "$argPath" ]; then
    log_step "Downloading $argURL -> $argPath"
    sudo wget "$argURL" -O "$argPath"
    log_success "Downloaded to: $argPath"
else
    log_info "File already exists at: $argPath — skipping download."
fi
