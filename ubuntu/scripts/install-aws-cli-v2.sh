#!/bin/bash
# =============================================================================
# INSTALL AWS CLI V2
# =============================================================================
# Installs AWS CLI v2 for x86_64 Linux from the official AWS distribution.
#
# Package installed:
#   aws-cli-v2  — AWS command-line interface
# =============================================================================
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
wget_download="$script_dir/../helper-scripts/wget-download.sh"
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

if [ ! -f "$wget_download" ]; then
    log_error "wget helper not found at: $wget_download"
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v aws &>/dev/null && aws --version 2>&1 | grep -q '^aws-cli/2\.'; then
    log_info "AWS CLI v2 already installed ($(aws --version 2>&1)). Skipping."
    exit 0
fi

# =========================
# AWS CLI v2 installation
# =========================

log_step "Installing AWS CLI v2 prerequisites..."
$apt_get_install unzip wget

aws_cli_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
aws_cli_tmp_dir="$(mktemp -d /tmp/aws-cli-v2.XXXXXX)"
aws_cli_archive="$aws_cli_tmp_dir/awscliv2.zip"

trap 'rm -rf "$aws_cli_tmp_dir"' EXIT

log_info "Downloading AWS CLI v2..."
"$wget_download" "$aws_cli_url" "$aws_cli_archive"

log_info "Extracting AWS CLI v2 installer..."
unzip -q "$aws_cli_archive" -d "$aws_cli_tmp_dir"

log_step "Installing AWS CLI v2..."
sudo "$aws_cli_tmp_dir/aws/install"

# =========================
# Verification
# =========================

hash -r

if ! command -v aws &>/dev/null || ! aws --version 2>&1 | grep -q '^aws-cli/2\.'; then
    log_error "AWS CLI v2 installation completed, but its version check failed."
    exit 1
fi

# =========================
# Post-install notes
# =========================

log_success "AWS CLI v2 installed successfully."
log_info "Version: $(aws --version 2>&1)"
log_info "Configure: aws configure"
log_info "Verify:    aws sts get-caller-identity"

## =========================
## First-run workflow
## =========================
##
## 1. Configure credentials and a default region:
##      aws configure
##
## 2. Verify the active AWS identity:
##      aws sts get-caller-identity
##
## 3. Optional: configure AWS IAM Identity Center (SSO):
##      aws configure sso
