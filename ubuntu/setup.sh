#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 <config_file> [<section>...]"
}

# Check if jq is installed
if ! dpkg -s jq >/dev/null 2>&1; then
    echo "jq is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install jq -y
fi

# Read config values from JSON file
read_config() {
    local json_file=$1
    local section=$2
    local key=$3

    jq -r ".$section.$key[]" "$json_file"
    ##jq -r ".$section.$key[]" "$json_file" | jq -r '.[]'
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

# Change directory to where this script resides
cd "$(dirname "$0")"

# Read config values from the JSON file for each section
for ((i = 2; i <= $#; i++)); do
    section="${!i}"
    required_scripts=($(read_config "$config_file" "$section" "REQUIRED"))
    optional_scripts=($(read_config "$config_file" "$section" "OPTIONAL"))

    # Check if required scripts are defined
    if [ ${#required_scripts[@]} -eq 0 ]; then
        echo "Error! No required scripts defined for section: $section"
        display_usage
        exit 1
    fi

    echo "Running scripts for section: $section"

# Run the required scripts
for script in "${required_scripts[@]}"; do
    # Convert '@' to whitespace in the script content
    converted_script=${script//@/ }
    # Run the script
    echo "Running script: $converted_script"
    bash -c "$converted_script"
    echo "Finished running script: $converted_script"
    echo ""
done


    # Run the optional scripts
    for script in "${optional_scripts[@]}"; do
        # Convert '@' to whitespace in the script content
        converted_script=${script//@/ }
        # Prompt to execute script
        read -rp "Do you want to run '$converted_script'? (Y/N): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            echo "Running optional script: $converted_script"
            bash "$script"
            echo "Finished running optional script: $converted_script"
            echo ""
        else
            echo "Skipping optional script: $converted_script"
            echo ""
        fi
    done

    echo "Finished running scripts for section: $section"
    echo ""
done
