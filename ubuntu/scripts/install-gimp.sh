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

if command -v gimp &>/dev/null; then
    log_info "GIMP already installed. Skipping."
    exit 0
fi

# =========================
# GIMP installation
# =========================

log_step "Installing GIMP..."
$apt_get_install gimp gimp-data-extras

# =========================
# Post-install notes
# =========================

log_success "GIMP installed successfully."
log_info "Verify:  gimp --version"
log_info "Launch:  gimp"
log_info "Docs:    https://docs.gimp.org/"

## =========================
## First-run workflow
## =========================
##
##   1. Launch GIMP:  gimp
##   2. On first run, GIMP initialises its user config at ~/.config/GIMP/
##   3. To import Photoshop brushes (.abr):
##      Filters → Script-Fu → Console, or drop files into ~/.config/GIMP/<ver>/brushes/
##   4. For batch processing from the CLI:
##      gimp -i -b '(gimp-quit 0)'   (non-interactive mode)
