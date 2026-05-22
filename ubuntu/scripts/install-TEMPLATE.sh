#!/bin/bash
# =============================================================================
# INSTALL SCRIPT TEMPLATE
# =============================================================================
# Copy this file to install-<tool>.sh and replace every TOOL_NAME / CAPS
# placeholder. Delete comment blocks once you've acted on them.
#
# Naming: install-<tool>.sh  (lowercase, hyphens, matches the tool/package)
# Register: add the script path to ubuntu/config/env_setup.json (use @ for spaces)
# =============================================================================
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"
# write_line="$script_dir/../helper-scripts/write-text-line-in-file.sh"  # uncomment if you need to append to ~/.bash_aliases or other dotfiles

# --- Validate logging first (plain echo — logger not sourced yet) ---
if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

# --- Validate remaining helpers (use log_error now that logger is live) ---
if [ ! -f "$apt_get_install" ]; then
    log_error "apt-get helper not found at: $apt_get_install"
    exit 1
fi

# if [ ! -f "$write_line" ]; then
#     log_error "write-text-line-in-file helper not found at: $write_line"
#     exit 1
# fi

# =========================
# Idempotency guard (optional but preferred)
# =========================
# Choose one of the patterns below, or omit if the tool has no reliable check.

# Pattern A — version string match (good for versioned binaries):
# TOOL_VERSION="1.2.3"
# if TOOL_NAME --version 2>/dev/null | grep -q "TOOL_NAME version ${TOOL_VERSION}"; then
#     log_info "TOOL_NAME v${TOOL_VERSION} already installed. Skipping."
#     exit 0
# fi

# Pattern B — command presence (good for apt packages):
# if command -v TOOL_NAME &>/dev/null; then
#     log_info "TOOL_NAME already installed. Skipping."
#     exit 0
# fi

# Pattern C — file/config existence guard (good for GPG keys, repo lists, etc.):
# Use inline [ ! -f ... ] checks around each step (see Proton VPN example).

# =========================
# TOOL_NAME installation
# =========================

log_info "Installing TOOL_NAME dependencies..."
$apt_get_install dep1 dep2   # replace with actual dependencies; apt_get_install is idempotent

# --- Download (if not an apt package) ---
# TOOL_VERSION="1.2.3"
# TOOL_FILE="tool-${TOOL_VERSION}-linux-amd64.tar.gz"
# TOOL_URL="https://example.com/releases/v${TOOL_VERSION}/${TOOL_FILE}"
# TOOL_TMP="/tmp/${TOOL_FILE}"
#
# log_info "Downloading TOOL_NAME v${TOOL_VERSION}..."
# if [ ! -f "$TOOL_TMP" ]; then
#     wget -q "$TOOL_URL" -O "$TOOL_TMP"
# fi
#
# log_info "Extracting to /usr/local..."
# sudo tar -C /usr/local -xzf "$TOOL_TMP"
# rm -f "$TOOL_TMP"

# --- GPG key + APT repo (if tool ships its own repo) ---
# KEYRING_PATH="/usr/share/keyrings/TOOL_NAME-archive-keyring.gpg"
# REPO_LIST="/etc/apt/sources.list.d/TOOL_NAME.list"
#
# if [ ! -f "$KEYRING_PATH" ]; then
#     log_info "Adding TOOL_NAME GPG key..."
#     wget -qO- https://example.com/public_key.asc \
#         | gpg --dearmor \
#         | sudo tee "$KEYRING_PATH" > /dev/null
# else
#     log_info "TOOL_NAME GPG key already present."
# fi
#
# if [ ! -f "$REPO_LIST" ]; then
#     log_info "Adding TOOL_NAME APT repository..."
#     echo "deb [signed-by=$KEYRING_PATH] https://example.com/debian stable main" \
#         | sudo tee "$REPO_LIST" > /dev/null
#     sudo apt update
# else
#     log_info "TOOL_NAME APT repository already present."
# fi
#
# log_info "Installing TOOL_NAME..."
# $apt_get_install TOOL_PACKAGE_NAME

# --- systemd services (if needed) ---
# log_info "Enabling TOOL_NAME.service..."
# sudo systemctl daemon-reload
# sudo systemctl enable TOOL_NAME
# sudo systemctl start TOOL_NAME
#
# if sudo systemctl is-active --quiet TOOL_NAME; then
#     log_success "TOOL_NAME.service is running."
# else
#     log_error "TOOL_NAME.service failed to start. Check: sudo journalctl -u TOOL_NAME"
#     exit 1
# fi

# --- User/group changes (if needed) ---
# sudo usermod -aG GROUP_NAME "$USER"
# log_info "You must log out or reboot for group changes to take effect."

# --- Dotfile additions (if needed; uncomment write_line above first) ---
# $write_line ~/.bash_aliases "alias SHORTCUT='FULL_COMMAND'"

# =========================
# Post-install notes
# =========================

log_success "TOOL_NAME installed successfully."
log_info "Verify:  TOOL_NAME --version"
log_info "Test:    TOOL_NAME <basic-command>"
# log_info "Docs:    https://example.com/docs"

## =========================
## First-run workflow
## =========================
##
## Replace this block with any manual steps the user must take after the script runs.
## Examples:
##   1. Sign in:   TOOL_NAME login
##   2. Configure: TOOL_NAME init
##   3. Test:      TOOL_NAME status
