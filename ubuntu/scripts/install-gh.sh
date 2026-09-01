#!/bin/bash
# =============================================================================
# INSTALL GITHUB CLI
# =============================================================================
# Installs GitHub CLI from GitHub's official APT repository so that future
# updates are delivered through APT.
#
# Package installed:
#   gh  - GitHub's official command-line interface
# =============================================================================
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

if [ ! -x "$apt_get_install" ]; then
    log_error "apt-get helper is missing or not executable: $apt_get_install"
    exit 1
fi

# =========================
# Preconditions
# =========================

if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install GitHub CLI."
    exit 1
fi

if ! command -v dpkg &>/dev/null; then
    log_error "dpkg is required to configure the GitHub CLI APT repository."
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v gh &>/dev/null; then
    if installed_version="$(gh --version 2>&1)"; then
        installed_version="${installed_version%%$'\n'*}"
        log_info "GitHub CLI is already installed ($installed_version). Skipping."
        exit 0
    fi

    log_error "An existing gh executable failed its version check."
    exit 1
fi

# =========================
# GitHub CLI repository
# =========================

log_step "Installing GitHub CLI prerequisites..."
"$apt_get_install" ca-certificates wget

keyring_path="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
repo_list="/etc/apt/sources.list.d/github-cli.list"

sudo install -m 0755 -d /etc/apt/keyrings /etc/apt/sources.list.d

if [ ! -f "$keyring_path" ]; then
    log_info "Adding the GitHub CLI repository signing key..."
    keyring_tmp="$(mktemp /tmp/githubcli-keyring.XXXXXX)"
    trap 'rm -f "$keyring_tmp"' EXIT

    wget -nv -O "$keyring_tmp" \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg
    sudo install -m 0644 "$keyring_tmp" "$keyring_path"
else
    log_info "GitHub CLI repository signing key already present."
fi

if [ ! -f "$repo_list" ]; then
    log_info "Adding GitHub's official APT repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring_path}] https://cli.github.com/packages stable main" \
        | sudo tee "$repo_list" > /dev/null
else
    log_info "GitHub CLI APT repository already configured."
fi

# =========================
# GitHub CLI installation
# =========================

log_step "Installing GitHub CLI..."
"$apt_get_install" gh

# =========================
# Verification
# =========================

hash -r

if ! command -v gh &>/dev/null; then
    log_error "GitHub CLI was installed, but gh is not available on PATH."
    exit 1
fi

if ! installed_version="$(gh --version 2>&1)"; then
    log_error "GitHub CLI was installed, but its version check failed."
    exit 1
fi

installed_version="${installed_version%%$'\n'*}"

# =========================
# Post-install notes
# =========================

log_success "GitHub CLI installed successfully."
log_info "Version:      $installed_version"
log_info "Authenticate: gh auth login"
log_info "Verify auth:  gh auth status"

## =========================
## First-run workflow
## =========================
##
## 1. Authenticate with GitHub:
##      gh auth login
##
## 2. Verify the authenticated account:
##      gh auth status
##
## 3. Test repository access:
##      gh repo list
