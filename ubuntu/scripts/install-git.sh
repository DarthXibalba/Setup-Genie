#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper-scripts/apt-get-install.sh"

# Define valid flags
declare -a valid_flags=("personal" "work")

# Function to display script usage
display_usage() {
    local valid_flags_string="${valid_flags[*]}"
    local usage_message="Usage: $0 [${valid_flags_string// / | }]"
    echo "$usage_message"
}

# Declare the global variables
declare config_file="$script_dir/../config/gitconfig.json"
declare config_section
declare username
declare email

# Function to read username and email from config file
read_config_values() {
    local key_username="USERNAME"
    local key_email="EMAIL"

    username=$(jq -r ".${config_section}.${key_username}" "$config_file")
    email=$(jq -r ".${config_section}.${key_email}" "$config_file")
}

# Check if the script is run without any arguments
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

# Check if more than one flag is provided
if [ $# -gt 1 ]; then
    echo "Error! Only one flag can be provided."
    display_usage
    exit 1
fi

# Get the flag from the command-line argument
flag="$1"

# Check if the flag is a valid flag
if [[ " ${valid_flags[*]} " =~ " ${flag} " ]]; then
    config_section="$flag"
else
    # Invalid flag provided
    display_usage
    exit 1
fi

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

# Read the username and email from the config file
read_config_values

# Check if username and email are set
if [ -z "${username}" ]; then
    echo "Error! Invalid config file: Missing USERNAME in [$config_section] section."
    exit 1
fi

if [ -z "${email}" ]; then
    echo "Error! Invalid config file: Missing EMAIL in [$config_section] section."
    exit 1
fi

# Install Git if not already installed
$apt_get_install git

# Check if user.name and user.email are already set
existing_username=$(git config --global --get user.name)
existing_email=$(git config --global --get user.email)

if [ -z "${existing_username}" ] || [ -z "${existing_email}" ]; then
    # Configure Git if user.name or user.email is not set
    if ! git config --global user.name "$username" || ! git config --global user.email "$email"; then
        echo "Error! Failed to configure Git. Please check your Git installation and try again."
        exit 1
    fi

    git config --global credential.helper store
    echo "Git configured with username '$username' and email '$email'."
else
    echo "Git user.name '$existing_username' and user.email '$existing_email' are already set."
fi
