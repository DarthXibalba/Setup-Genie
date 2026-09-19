#!/bin/bash
# =============================================================================
# INSTALL NODE.JS
# =============================================================================
# Installs exactly Node.js 24.21.0 from the official archive after verifying its
# SHA-256 checksum. Supports x86-64 and ARM64 on Fedora.
#
# Commands installed:
#   node  - JavaScript runtime
#   npm   - bundled package manager
#   npx   - bundled package runner
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

fail() {
    log_error "$*" >&2
    exit 1
}

# =========================
# Preconditions
# =========================

readonly node_version="24.21.0"

[[ -r /etc/os-release ]] || fail "Cannot identify the operating system."
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == "fedora" ]] || fail "This installer supports Fedora only."

case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) fail "Unsupported architecture: $(uname -m). Expected x86-64 or ARM64." ;;
esac

if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install Node.js."
    exit 1
fi

readonly release="node-v${node_version}-linux-${arch}"
readonly install_dir="/usr/local/lib/nodejs/${release}"
readonly base_url="https://nodejs.org/dist/v${node_version}"
readonly archive="${release}.tar.xz"

# Refuse directory conflicts before changing any command links.
for name in node npm npx; do
    if [[ -d "/usr/local/bin/$name" && ! -L "/usr/local/bin/$name" ]]; then
        fail "/usr/local/bin/$name is a directory; move it before installing."
    fi
done

# =========================
# Node.js installation (skip download when already present)
# =========================

if [[ ! -e "$install_dir" && ! -L "$install_dir" ]]; then
    log_step "Installing Node.js dependencies..."
    "$dnf_install" ca-certificates curl tar xz coreutils libstdc++

    work_dir="$(mktemp -d)"
    trap 'rm -rf -- "$work_dir"' EXIT

    log_step "Downloading Node.js v${node_version} for ${arch}..."
    curl --fail --show-error --location --proto '=https' --proto-redir '=https' \
        --retry 3 "$base_url/SHASUMS256.txt" -o "$work_dir/SHASUMS256.txt" \
        || fail "Cannot fetch checksums for v${node_version}; no other version will be installed."
    curl --fail --show-error --location --proto '=https' --proto-redir '=https' \
        --retry 3 "$base_url/$archive" -o "$work_dir/$archive" \
        || fail "Cannot download $archive."

    # Check only the selected archive; reject missing or duplicate checksum entries.
    awk -v file="$archive" '$2 == file { print }' \
        "$work_dir/SHASUMS256.txt" > "$work_dir/selected.sha256"
    [[ "$(wc -l < "$work_dir/selected.sha256")" -eq 1 ]] \
        || fail "Expected exactly one checksum for $archive."
    (cd "$work_dir" && sha256sum --check selected.sha256) \
        || fail "Archive checksum verification failed."

    log_step "Extracting Node.js..."
    tar --extract --xz --file "$work_dir/$archive" --directory "$work_dir" --no-same-owner
    [[ "$("$work_dir/$release/bin/node" --version)" == "v$node_version" ]] \
        || fail "Downloaded Node.js cannot run or has the wrong version."

    sudo install -d -m 0755 /usr/local/lib/nodejs
    sudo cp -a -- "$work_dir/$release" "$install_dir"
    sudo chown -R root:root "$install_dir"
else
    log_info "Node.js installation already present at $install_dir. Verifying..."
fi

# =========================
# Verification
# =========================

[[ "$("$install_dir/bin/node" --version)" == "v$node_version" ]] \
    || fail "Existing installation at $install_dir is invalid."
"$install_dir/bin/node" "$install_dir/lib/node_modules/npm/bin/npm-cli.js" --version \
    || fail "Bundled npm failed verification."

# =========================
# Command links
# =========================

log_step "Linking Node.js commands into /usr/local/bin..."
sudo install -d -m 0755 /usr/local/bin
for name in node npm npx; do
    sudo ln -sfnT "$install_dir/bin/$name" "/usr/local/bin/$name"
done

# =========================
# Post-install notes
# =========================

log_success "Node.js installed successfully."
log_info "Version: $(/usr/local/bin/node --version)"
log_info "Location: $install_dir"
log_info "Verify:  node --version"
log_info "Test:    npm --version"
log_info "Ensure /usr/local/bin comes before other Node.js installations on PATH."

## =========================
## First-run workflow
## =========================
##
## 1. Refresh command lookup in an existing Bash session:
##      hash -r
##
## 2. Verify the runtime and package manager:
##      node --version
##      npm --version
##
## 3. Initialize a package in your project directory:
##      npm init
