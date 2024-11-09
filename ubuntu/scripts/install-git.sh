#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"

declare config_file="$script_dir/../config/gitconfig.json"
declare config_section
declare username
declare email
declare pat_token
declare -a valid_flags=("personal" "work")

# Functions to configure git users and credentials
configure_git() {
    existing_username=$(git config --global --get user.name)
    existing_email=$(git config --global --get user.email)
    sudo_username=$(sudo git config --global --get user.name)
    sudo_email=$(sudo git config --global --get user.email)

    if [ -z "${existing_username}" ] || [ -z "${existing_email}" ]; then
        # Configure Git if user.name or user.email is not set
        if ! git config --global user.name "$username" || ! git config --global user.email "$email"; then
            echo "Error! Failed to configure Git. Please check your Git installation and try again."
            exit 1
        fi

        git config --global credential.helper store
        git config --global --add url."https://$pat_token@github.azc.ext.hp.com".insteadOf "https://github.azc.ext.hp.com"
        echo "Git configured with username '$username' and email '$email'."
    else
        echo "Git user.name '$existing_username' and user.email '$existing_email' are already set."
    fi

}

configure_sudo_git() {
    existing_username=$(sudo git config --global --get user.name)
    existing_email=$(sudo git config --global --get user.email)

    if [ -z "${existing_username}" ] || [ -z "${existing_email}" ]; then
        # Configure Git if user.name or user.email is not set
        if ! sudo git config --global user.name "$username" || ! sudo git config --global user.email "$email"; then
            echo "Error! Failed to configure sudo git. Please check your sudo git installation and try again."
            exit 1
        fi

        sudo git config --global credential.helper store
        sudo git config --global --add url."https://$pat_token@github.azc.ext.hp.com".insteadOf "https://github.azc.ext.hp.com"
        echo "Sudo git configured with username '$username' and email '$email'."
    else
        echo "Sudo git user.name '$existing_username' and user.email '$existing_email' are already set."
    fi

}

# Function to display script usage
display_usage() {
    local valid_flags_string="${valid_flags[*]}"
    local usage_message="Usage: $0 [${valid_flags_string// / | }]"
    echo "$usage_message"
}

# Function to read username, email, & PAT from config file
read_config_values() {
    local key_username="USERNAME"
    local key_email="EMAIL"
    local key_pat="PAT"

    username=$(jq -r ".${config_section}.${key_username}" "$config_file")
    email=$(jq -r ".${config_section}.${key_email}" "$config_file")
    pat_token=$(jq -r ".${config_section}.${key_pat}" "$config_file")

    if [ -z "${username}" ]; then
    echo "Error! Invalid config file: Missing USERNAME in [$config_section] section."
        exit 1
    elif [ -z "${email}" ]; then
        echo "Error! Invalid config file: Missing EMAIL in [$config_section] section."
        exit 1
    elif [ -z "${pat_token}" ]; then
        echo "Error! Invalid config file: Missing PAT in [$config_section] section."
        exit 1
    fi
}

# Validation Check
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "Error! Only one flag can be provided."
    display_usage
    exit 1
fi

flag="$1"
if [[ " ${valid_flags[*]} " =~ " ${flag} " ]]; then
    config_section="$flag"
else
    # Invalid flag provided
    display_usage
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

# Main
$apt_get_install git
read_config_values
configure_git
configure_sudo_git
