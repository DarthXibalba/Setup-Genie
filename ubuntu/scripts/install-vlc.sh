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
# Idempotency guard
# =========================

if command -v vlc &>/dev/null; then
    log_info "VLC already installed. Skipping."
    exit 0
fi

# =========================
# VLC installation
# =========================

log_step "Installing VLC..."
$apt_get_install vlc

# =========================
# Post-install notes
# =========================

log_success "VLC installed successfully."
log_info "Verify:  vlc --version"
log_info "Launch:  vlc"
log_info "Docs:    https://www.videolan.org/doc/"

## =========================
## First-run workflow
## =========================
##
##   1. Open a file:          vlc <file>
##   2. Open network stream:  Media → Open Network Stream  (Ctrl+N)
##   3. Record / convert:     Media → Convert/Save  (Ctrl+R)
