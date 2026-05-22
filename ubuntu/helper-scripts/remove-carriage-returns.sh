#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

# =========================
# Validate args
# =========================

if [ $# -ne 2 ]; then
    log_error "Expected 2 arguments, got $#."
    log_info  "This script removes Windows carriage return (^M) from input_file and saves it to output_file."
    log_info  "Usage: $0 <input_file> <output_file>"
    exit 1
fi

input_file="$1"
output_file="$2"

# =========================
# Remove carriage returns
# =========================

tr -d '\r' < "$input_file" > "$output_file"

log_success "Removed carriage returns from: $input_file"
log_info    "Saved to:                       $output_file"
