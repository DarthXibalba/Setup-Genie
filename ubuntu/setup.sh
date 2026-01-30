#!/usr/bin/env bash

# =========================
# Functions
# =========================

display_usage() {
    log_info "Usage: $0 <section>..."
}

read_config() {
    local json_file="$1"
    local section="$2"
    local key="$3"

    jq -r ".$section.$key[]" "$json_file"
}

get_sections() {
    local json_file="$1"
    jq -r 'keys[]' "$json_file"
}

# =========================
# Paths + logging
# =========================

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

config_file="$script_dir/config/env_setup.json"

# =========================
# Preconditions
# =========================

if ! dpkg -s jq >/dev/null 2>&1; then
    log_warn "jq is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y jq
    log_success "jq installed"
fi

if [ ! -f "$config_file" ]; then
    log_error "Config file '$config_file' not found!"
    exit 1
fi

valid_sections=($(get_sections "$config_file"))
formatted_valid_sections="{ $(printf "%s " "${valid_sections[@]}")}"

# =========================
# Argument validation
# =========================

if [ $# -lt 1 ]; then
    log_error "No sections specified!"
    log_info "Valid sections are: $formatted_valid_sections"
    display_usage
    exit 1
fi

invalid_sections=()
for section in "$@"; do
    if [[ ! " ${valid_sections[*]} " =~ " ${section} " ]]; then
        invalid_sections+=("$section")
    fi
done

if [ ${#invalid_sections[@]} -ne 0 ]; then
    log_error "Invalid sections specified: ${invalid_sections[*]}"
    log_info "Valid sections are: $formatted_valid_sections"
    display_usage
    exit 1
fi

# =========================
# Execution
# =========================

for section in "$@"; do
    required_scripts=($(read_config "$config_file" "$section" "REQUIRED"))
    optional_scripts=($(read_config "$config_file" "$section" "OPTIONAL"))

    if [ ${#required_scripts[@]} -eq 0 ]; then
        log_warn "No required scripts defined for section: $section"
        continue
    fi

    log_step "Running REQUIRED scripts for section: $section"

    for script in "${required_scripts[@]}"; do
        converted_script="${script_dir}/${script//@/ }"
        log_info "Running script: $converted_script"

        if bash -c "$converted_script"; then
            log_success "Finished: $converted_script"
        else
            log_error "Script failed: $converted_script"
            exit 1
        fi
        echo
    done

    for script in "${optional_scripts[@]}"; do
        converted_script="${script_dir}/${script//@/ }"
        read -rp "Run optional script '$converted_script'? (Y/N): " choice

        if [[ $choice =~ ^[Yy]$ ]]; then
            log_info "Running optional script: $converted_script"
            if bash -c "$converted_script"; then
                log_success "Finished optional script: $converted_script"
            else
                log_error "Optional script failed: $converted_script"
                exit 1
            fi
        else
            log_warn "Skipped optional script: $converted_script"
        fi
        echo
    done

    log_step "Completed section: $section"
    echo
done

log_success "Environment setup complete 🎉"
