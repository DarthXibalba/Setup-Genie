#!/bin/bash
# =============================================================================
# REPAIR HASHICORP APT KEY
# =============================================================================
# Refreshes the repository key after checking the fingerprint published at:
# https://www.hashicorp.com/en/official-packaging-guide
# =============================================================================
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
# Preconditions
# =========================

for tool in wget gpg sudo; do
    if ! command -v "$tool" &>/dev/null; then
        log_error "$tool is required to refresh the HashiCorp repository key."
        exit 1
    fi
done

# =========================
# Download and verify key
# =========================

expected_fingerprint="D55C0D1AC78A8D8126CB631CFC9CA96ACA026560"
keyring_path="/usr/share/keyrings/hashicorp-archive-keyring.gpg"
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -m 0700 "$work_dir/gnupg"

log_step "Downloading HashiCorp's current package-signing key..."
wget -nv -O "$work_dir/key.asc" https://apt.releases.hashicorp.com/gpg
fingerprint="$(gpg --homedir "$work_dir/gnupg" --batch --show-keys --with-colons \
    "$work_dir/key.asc" | awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print $10; primary = 0 }')"

if [ "$fingerprint" != "$expected_fingerprint" ]; then
    log_error "Unexpected HashiCorp key fingerprint: $fingerprint. Existing key left unchanged."
    exit 1
fi

# =========================
# Install key and refresh indexes
# =========================

gpg --homedir "$work_dir/gnupg" --batch --yes --dearmor \
    --output "$work_dir/key.gpg" "$work_dir/key.asc"
sudo install -m 0644 "$work_dir/key.gpg" "$keyring_path"
sudo apt-get update -o APT::Update::Error-Mode=any

# =========================
# Post-install notes
# =========================

log_success "HashiCorp package-signing key refreshed and APT indexes updated."
log_info "You can now rerun the installer that encountered the APT warning."
