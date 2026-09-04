#!/bin/bash
# =============================================================================
# INSTALL TERRAFORM
# =============================================================================
# Installs Terraform from HashiCorp's official Fedora RPM repository so that
# future updates are delivered through DNF.
#
# Package installed:
#   terraform  - HashiCorp's infrastructure-as-code command-line tool
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
    log_error "sudo is required to install Terraform."
    exit 1
fi

if ! command -v dnf &>/dev/null; then
    log_error "dnf is required to install Terraform."
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v terraform &>/dev/null; then
    if installed_version="$(terraform version 2>&1)"; then
        installed_version="${installed_version%%$'\n'*}"
        log_info "Terraform is already installed ($installed_version). Skipping."
        exit 0
    fi

    log_error "An existing terraform executable failed its version check."
    exit 1
fi

# =========================
# HashiCorp repository
# =========================

log_step "Installing Terraform repository prerequisites..."
"$dnf_install" ca-certificates wget

repo_file="/etc/yum.repos.d/hashicorp.repo"
repo_url="https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"

if [ ! -f "$repo_file" ]; then
    log_step "Adding HashiCorp's official Fedora repository..."
    repo_tmp="$(mktemp /tmp/hashicorp-repo.XXXXXX)"
    trap 'rm -f "$repo_tmp"' EXIT

    wget -nv -O "$repo_tmp" "$repo_url"
    sudo install -m 0644 "$repo_tmp" "$repo_file"

    log_success "HashiCorp repository added."
else
    log_info "HashiCorp RPM repository already configured."
fi

# =========================
# Terraform installation
# =========================

log_step "Installing Terraform..."
"$dnf_install" terraform

# =========================
# Verification
# =========================

hash -r

if ! command -v terraform &>/dev/null; then
    log_error "Terraform was installed, but it is not available on PATH."
    exit 1
fi

if ! installed_version="$(terraform version 2>&1)"; then
    log_error "Terraform was installed, but its version check failed."
    exit 1
fi

installed_version="${installed_version%%$'\n'*}"

# =========================
# Post-install notes
# =========================

log_success "Terraform installed successfully."
log_info "Version: $installed_version"
log_info "Verify:  terraform version"
log_info "Start:   terraform -help"

## =========================
## First-run workflow
## =========================
##
## 1. Verify the installation:
##      terraform version
##
## 2. In a directory containing Terraform configuration, initialize it:
##      terraform init
##
## 3. Preview proposed infrastructure changes:
##      terraform plan
