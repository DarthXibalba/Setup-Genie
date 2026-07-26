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

if [ "$#" -ne 2 ]; then
    log_error "Expected 2 arguments, got $#."
    log_info  "Writes a line of text into a file, if it does not already exist."
    log_info  "Usage: $0 <filename> '<text to write>'"
    exit 1
fi

filename="$1"
text_to_write="$2"

# =========================
# Write line to file
# =========================

if [ ! -f "$filename" ]; then
    log_error "File not found at: $filename"
    exit 1
fi

if grep -Fxq "$text_to_write" "$filename"; then
    log_info "Line already exists in $filename — no changes made."
else
    echo "$text_to_write" >> "$filename"
    log_success "Line appended to $filename."
fi
