#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 <config_file> [<section>...]"
}

# Read config values from INI file
read_config() {
    local ini_file=$1
    local section=$2
    local key=$3

    # Use awk to parse the INI file
    awk -F '=' -v section="$section" -v key="$key" '$1 == "[" section "]" { in_section = 1; next } in_section && $1 == key { print $2; exit }' "$ini_file"
}

# Check if a config file is provided
if [ -z "$1" ]; then
    echo "Error! Config file not specified!"
    display_usage
    exit 1
fi

config_file=$1

# Check if sections are provided
if [ $# -lt 2 ]; then
    echo "Error! No sections specified!"
    display_usage
    exit 1
fi

# Read config values from the INI file for each section
for ((i = 2; i <= $#; i++)); do
    section="${!i}"
    required_scripts=($(read_config "$config_file" "$section" "REQUIRED[]"))
    optional_scripts=($(read_config "$config_file" "$section" "OPTIONAL[]"))

    # Check if required scripts are defined
    if [ ${#required_scripts[@]} -eq 0 ]; then
        echo "Error! No required scripts defined for section: $section"
        display_usage
        exit 1
    fi

    echo "Running scripts for section: $section"

    # Run the required scripts
    for script in "${required_scripts[@]}"; do
        echo "Running script: $script"
        # Execute the script here
        bash "$script"
    done

    # Prompt to execute optional scripts
    read -rp "Do you want to run the optional scripts? (Y/N): " choice
    if [[ $choice =~ ^[Yy]$ ]]; then
        # Run the optional scripts
        for script in "${optional_scripts[@]}"; do
            echo "Running optional script: $script"
            # Execute the script here
            bash "$script"
        done
    else
        echo "Skipping optional scripts."
    fi

    echo "Finished running scripts for section: $section"
done
