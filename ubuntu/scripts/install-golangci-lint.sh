#!/bin/bash
set -euo pipefail

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
# Download and verify the latest release
# =========================

# Keep the original installation location when upgrading. For a local install,
# create your bin directory first and set BINDIR, e.g. BINDIR="$HOME/.local/bin".
install_dir="${BINDIR:-/usr/local/go/bin}"
installed_binary="$install_dir/golangci-lint"
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT

log_step "Downloading the current golangci-lint installer..."
# The old master/install.sh also matched the archive's .sbom.json checksum.
# The official installer matches the end of the archive filename.
if ! curl -fsSL --retry 3 --connect-timeout 15 \
    https://golangci-lint.run/install.sh -o "$work_dir/install.sh"; then
    log_error "Could not download the installer. golangci-lint was not updated."
    exit 1
fi

log_step "Downloading and verifying the latest golangci-lint release..."
# No version argument means latest. Stage the checksum-verified binary before
# replacing the existing installation; only the final copy may need sudo.
if ! sh "$work_dir/install.sh" -b "$work_dir/bin"; then
    log_error "The installer failed. golangci-lint was not updated."
    exit 1
fi

if ! downloaded_version="$("$work_dir/bin/golangci-lint" --version)"; then
    log_error "The downloaded binary failed its version check. golangci-lint was not updated."
    exit 1
fi

# =========================
# Install or update
# =========================

install_command=(install)
if [[ ! -w "$install_dir" ]]; then
    install_command=(sudo install)
fi

if ! "${install_command[@]}" -D -m 0755 "$work_dir/bin/golangci-lint" "$installed_binary"; then
    log_error "Could not install golangci-lint into $install_dir."
    exit 1
fi

if ! installed_version="$("$installed_binary" --version)"; then
    log_error "The installed binary failed its version check: $installed_binary"
    exit 1
fi

if [[ "$installed_version" != "$downloaded_version" ]]; then
    log_error "The installed version does not match the downloaded version."
    exit 1
fi

# =========================
# Post-install notes
# =========================

log_success "golangci-lint installed successfully at $installed_binary."
log_info "$installed_version"

hash -r
active_binary="$(command -v golangci-lint || true)"
if [[ -z "$active_binary" ]]; then
    log_warn "Add $install_dir to PATH to run golangci-lint by name."
elif [[ ! "$active_binary" -ef "$installed_binary" ]]; then
    log_warn "PATH currently selects $active_binary. Put $install_dir earlier in PATH to use the updated binary."
fi

log_info "Verify: $installed_binary --version"
log_info "Run in a Go project: golangci-lint run ./..."

## =========================
## First-run workflow
## =========================
##
## Rerun this script to update to the latest release.
## Verify the version selected by your shell: golangci-lint --version
