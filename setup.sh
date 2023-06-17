#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 <config_file>"
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

# Set default values
ENVIRONMENT=""
ENV_TYPE=""
PERSONAL_ACCESS_TOKEN=""

# Read config values from the INI file
ENVIRONMENT=$(read_config "$config_file" "settings" "ENVIRONMENT")
ENV_TYPE=$(read_config "$config_file" "settings" "ENV_TYPE")

# Check if both environment and environment type are set
if [ -z "${ENVIRONMENT}" ] || [ -z "${ENV_TYPE}" ]; then
    echo "Error! Must specify both environment and environment type in the config file!"
    display_usage
    exit 1
fi

# Update environment-specific configurations
if [ "$ENVIRONMENT" = "wsl" ]; then
    # Run WSL-specific commands
    echo "Setting up for WSL Ubuntu..."
    # ...
elif [ "$ENVIRONMENT" = "ubuntu" ]; then
    # Run Ubuntu-specific commands
    echo "Setting up for Ubuntu..."
    # ...
else
    echo "Error! Invalid environment: $ENVIRONMENT"
    display_usage
    exit 1
fi

# Update environment-specific configurations
if [ "$ENV_TYPE" = "work" ]; then
    # Run Work-specific commands
    echo "Setting up for work use..."
    # ...
elif [ "$ENV_TYPE" = "personal" ]; then
    # Run Personal-specific commands
    echo "Setting up for personal use with personal access token: $PERSONAL_ACCESS_TOKEN"
    # ...
else
    echo "Error! Invalid environment: $ENV_TYPE"
    display_usage
    exit 1
fi

# Read personal access token from file
pat_file="pat.ini"
if [ ! -f "$pat_file" ]; then
    echo "Error! Personal access token file not found: $pat_file"
    display_usage
    exit 1
fi

PERSONAL_ACCESS_TOKEN=$(cat "$pat_file")
