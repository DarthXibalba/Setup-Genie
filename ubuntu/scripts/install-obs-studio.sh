#!/bin/bash
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

if [ ! -f "$apt_get_install" ]; then
    log_error "apt-get helper not found at: $apt_get_install"
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v obs &>/dev/null; then
    log_info "OBS Studio already installed. Skipping."
    exit 0
fi

# =========================
# OBS Studio installation
# =========================

log_info "Installing OBS Studio dependencies..."
$apt_get_install software-properties-common ffmpeg

# --- OBS PPA (idempotent) ---
if ! find /etc/apt/sources.list.d/ -name "*.list" -exec grep -l "obsproject" {} \; 2>/dev/null | grep -q .; then
    log_info "Adding OBS Studio PPA (ppa:obsproject/obs-studio)..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    sudo apt-get update -q
else
    log_info "OBS Studio PPA already present."
fi

log_step "Installing OBS Studio..."
$apt_get_install obs-studio

# =========================
# Post-install notes
# =========================

log_success "OBS Studio installed successfully."
log_info "Verify:  obs --version"
log_info "Launch:  obs"
log_info "Docs:    https://obsproject.com/wiki/"

## =========================
## First-run workflow
## =========================
##
##   1. Launch OBS:   obs
##   2. Auto-configure wizard runs on first launch.
##      Choose your use case (streaming / recording) and let OBS benchmark
##      your hardware for optimal settings.
##   3. Virtual camera (for video calls):
##      Tools → Virtual Camera → Start
##   4. NVIDIA NVENC encoding (if GPU is available):
##      Settings → Output → Encoder → NVENC H.264
##   5. Streaming:
##      Settings → Stream → enter your platform key (Twitch, YouTube, etc.)
