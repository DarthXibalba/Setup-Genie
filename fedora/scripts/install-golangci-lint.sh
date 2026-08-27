#!/bin/bash
# =============================================================================
# INSTALL GOLANGCI-LINT
# =============================================================================
# Installs golangci-lint from Fedora's package repositories. Using the Fedora
# package keeps installation, upgrades, verification, and removal under DNF
# instead of executing a remotely hosted shell script as root.
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
    log_error "sudo is required to install golangci-lint."
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v golangci-lint &>/dev/null; then
    if installed_version="$(golangci-lint version 2>&1)"; then
        log_info "golangci-lint is already installed. Skipping."
        log_info "Version: $installed_version"
        exit 0
    fi

    log_warn "An existing golangci-lint executable failed its version check; reinstalling the Fedora package."
fi

# =========================
# Installation
# =========================

log_step "Installing golangci-lint from the Fedora repositories..."
"$dnf_install" golangci-lint

# =========================
# Verification
# =========================

hash -r

if ! command -v golangci-lint &>/dev/null; then
    log_error "golangci-lint was installed, but it is not available on PATH."
    exit 1
fi

if ! installed_version="$(golangci-lint version 2>&1)"; then
    log_error "golangci-lint was installed, but its version check failed."
    exit 1
fi

# =========================
# Post-install notes
# =========================

log_success "golangci-lint installed successfully."
log_info "Version: $installed_version"
log_info "Verify:  golangci-lint version"
log_info "Run:     golangci-lint run ./..."

## =========================
## First-run workflow
## =========================
##
## 1. Verify the installation:
##      golangci-lint version
##
## 2. Run all configured linters in a Go project:
##      golangci-lint run ./...
##
## 3. Upgrade with the rest of the Fedora packages:
##      sudo dnf upgrade golangci-lint
