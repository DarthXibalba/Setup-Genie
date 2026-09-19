#!/bin/bash
# =============================================================================
# INSTALL TERRAFORM
# =============================================================================
# Installs Terraform from HashiCorp's official Ubuntu APT repository so that
# future updates are delivered through APT.
#
# Package installed:
#   terraform  - HashiCorp's infrastructure-as-code command-line tool
# =============================================================================
set -euo pipefail

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

if [ ! -r /etc/os-release ]; then
    log_error "Cannot identify the operating system: /etc/os-release is missing."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
    log_error "This installer supports Ubuntu only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install Terraform."
    exit 1
fi

if ! command -v dpkg &>/dev/null; then
    log_error "dpkg is required to configure the HashiCorp APT repository."
    exit 1
fi

ubuntu_codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
if [ -z "$ubuntu_codename" ]; then
    log_error "Could not determine the Ubuntu release codename."
    exit 1
fi

# =========================
# HashiCorp repository
# =========================

log_step "Installing Terraform repository prerequisites..."
"$apt_get_install" ca-certificates gnupg wget

keyring_path="/usr/share/keyrings/hashicorp-archive-keyring.gpg"
repo_list="/etc/apt/sources.list.d/hashicorp.list"

if [ ! -f "$repo_list" ]; then
    log_step "Adding HashiCorp's official APT repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring_path}] https://apt.releases.hashicorp.com ${ubuntu_codename} main" \
        | sudo tee "$repo_list" > /dev/null

    log_success "HashiCorp repository added."
else
    log_info "HashiCorp APT repository already configured."
fi

# Refresh the key even when Terraform is already installed.
bash "$script_dir/repair-hashicorp-apt-key.sh"

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
# Terraform installation
# =========================

log_step "Installing Terraform..."
"$apt_get_install" terraform

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
