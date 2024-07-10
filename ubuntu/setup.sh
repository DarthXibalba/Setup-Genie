#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 <section>..."
}

# Function to read config values from JSON file
read_config() {
    local json_file=$1
    local section=$2
    local key=$3

    jq -r ".$section.$key[]" "$json_file"
}

# Check if jq is installed
if ! dpkg -s jq >/dev/null 2>&1; then
    echo "jq is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install jq -y
fi

# Get absolute path of config_file
script_dir=$(dirname "$(realpath "$0")")
config_file="$script_dir/config/env_setup.json"

# Check if config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file '$config_file' not found!"
    exit 1
fi

# Check if sections are provided as arguments
if [ $# -lt 1 ]; then
    echo "Error! No sections specified!"
    display_usage
    exit 1
fi

# Read config values from the JSON file for each section
for section in "$@"; do
    required_scripts=($(read_config "$config_file" "$section" "REQUIRED"))
    optional_scripts=($(read_config "$config_file" "$section" "OPTIONAL"))

    # Check if required scripts are defined
    if [ ${#required_scripts[@]} -eq 0 ]; then
        echo "Warning! No required scripts defined for section: $section"
        continue
    else
        echo "Running scripts for section: $section"
        for script in "${required_scripts[@]}"; do
            # Convert '@' to whitespace in the script content and expand the path
            converted_script="${script_dir}/${script//@/ }"
            echo "Running script: $converted_script"
            bash -c "$converted_script"
            echo "Finished running script: $converted_script"
            echo ""
        done

        # Run the optional scripts
        for script in "${optional_scripts[@]}"; do
            # Convert '@' to whitespace in the script content and expand the path
            converted_script="${script_dir}/${script//@/ }"
            # Prompt to execute script
            read -rp "Do you want to run '$converted_script'? (Y/N): " choice
            if [[ $choice =~ ^[Yy]$ ]]; then
                echo "Running optional script: $converted_script"
                bash -c "$converted_script"
                echo "Finished running optional script: $converted_script"
                echo ""
            else
                echo "Skipping optional script: $converted_script"
                echo ""
            fi
        done

        echo "Finished running scripts for section: $section"
        echo ""
    fi
done
