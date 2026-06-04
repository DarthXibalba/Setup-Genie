#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

# =========================
# Idempotency guard
# =========================

if [ -f "/opt/Postman/Postman" ]; then
    log_info "Postman already installed at /opt/Postman. Skipping."
    exit 0
fi

# =========================
# Postman installation
# =========================

postman_url="https://dl.pstmn.io/download/latest/linux_64"
postman_tmp="/tmp/postman-linux64.tar.gz"

log_info "Downloading Postman (latest)..."
wget -q "$postman_url" -O "$postman_tmp"

log_info "Extracting to /opt..."
sudo tar -C /opt -xzf "$postman_tmp"

rm -f "$postman_tmp"

log_info "Creating /usr/local/bin/postman symlink..."
sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman

# =========================
# Post-install notes
# =========================

log_success "Postman installed successfully."
log_info "Launch from terminal: postman"
log_info "Or search 'Postman' in your application launcher."

## =========================
## First-run workflow
## =========================
##
##   1. Launch: postman
##   2. Sign in or create a Postman account
##   3. Import existing collections if needed
