#!/bin/bash
# =============================================================================
# INSTALL GITHUB CLI
# =============================================================================
# Installs GitHub CLI from GitHub's official RPM repository so that future
# updates are delivered through DNF.
#
# Package installed:
#   gh  - GitHub's official command-line interface
# =============================================================================
set -euo pipefail

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
dnf_install="$script_dir/../helper-scripts/dnf-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

if [ ! -x "$dnf_install" ]; then
    log_error "DNF install helper is missing or not executable: $dnf_install"
    exit 1
fi

# =========================
# Preconditions
# =========================

if [ ! -r /etc/os-release ]; then
    log_error "Cannot identify the operating system: /etc/os-release is missing."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

if [ "${ID:-}" != "fedora" ]; then
    log_error "This installer supports Fedora only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install GitHub CLI."
    exit 1
fi

if ! command -v dnf &>/dev/null; then
    log_error "dnf is required to install GitHub CLI."
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

repo_file="/etc/yum.repos.d/gh-cli.repo"
repo_url="https://cli.github.com/packages/rpm/gh-cli.repo"

if [ ! -f "$repo_file" ]; then
    log_step "Adding GitHub's official RPM repository..."

    dnf_version="$(dnf --version 2>&1 | sed -n '1p')"
    if command -v dnf5 &>/dev/null || [[ "$dnf_version" == dnf5* || "$dnf_version" == 5.* ]]; then
        "$dnf_install" dnf5-plugins
        sudo dnf config-manager addrepo --from-repofile="$repo_url"
    else
        "$dnf_install" 'dnf-command(config-manager)'
        sudo dnf config-manager --add-repo "$repo_url"
    fi

    log_success "GitHub CLI repository added."
else
    log_info "GitHub CLI RPM repository already configured."
fi

# =========================
# GitHub CLI installation
# =========================

log_step "Installing GitHub CLI..."
"$dnf_install" gh

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
