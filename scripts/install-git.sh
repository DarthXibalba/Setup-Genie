#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 [--personal | --work]"
}

# Function to read username and email from config file
read_config_values() {
    local config_file=$1
    local config_section=$2
    local username_key="USERNAME"
    local email_key="EMAIL"

    local username=$(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /${username_key}/{print \$2}" "$config_file" | awk '{$1=$1};1')
    local email=$(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /${email_key}/{print \$2}" "$config_file" | awk '{$1=$1};1')

    echo "$username $email"
}

# Check if the script is run without any arguments
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

# Parse input flags
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --personal)
        config_section="personal"
        ;;
        --work)
        config_section="work"
        ;;
        *)
        # Invalid flag provided
        display_usage
        exit 1
        ;;
    esac

    shift
done

# Read the config file
config_file="gitconfig.ini"

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

# Read the username and email from the config file
read_result=$(read_config_values "$config_file" "$config_section")
read_successful=$?

if [ $read_successful -ne 0 ]; then
    echo "Error! Invalid config file: Missing required values in [$config_section] section."
    exit 1
fi

read -r username email <<< "$read_result"

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
if ! command -v git &>/dev/null; then
    if ! sudo apt-get install -y git; then
        echo "Error! Failed to install Git. Please check your internet connection and try again."
        exit 1
    fi
fi

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
    echo "Git user.name '$existing_username' and user.email '$existing_email' are already set
