#!/bin/bash

# Define valid flags
declare -a valid_flags=("personal" "work" "containerd")

# Function to display script usage
display_usage() {
    local valid_flags_string="${valid_flags[*]}"
    local usage_message="Usage: $0 [${valid_flags_string// / | }]"
    echo "$usage_message"
}

# Declare global variables
declare config_file="./config/gitconfig.json"
declare config_section
declare localpath
declare -a parsed_required
declare -a parsed_optional

# Function to parse the gitconfig.json file and return localpath, required repos, and optional repos
parse_config() {
    local key_localpath="LOCALPATH"
    local key_optional="OPTIONAL"
    local key_required="REQUIRED"
    local key_pat="PAT"

    # Read the localpath value
    localpath=$(jq -r ".${config_section}.${key_localpath}" "$config_file")
    # Remove leading and trailing double quotes from value
    localpath=$(eval "echo $(sed 's/^"\(.*\)"$/\1/' <<< "$localpath")")

    # Read the PAT value
    local pat=$(jq -r ".${config_section}.${key_pat}" "$config_file")

    # Read the required and optional repositories into their respective arrays
    local reqs
    local opts
    readarray -t reqs < <(jq -r ".${config_section}.${key_required}[]" "$config_file")
    readarray -t opts < <(jq -r ".${config_section}.${key_optional}[]" "$config_file")

    # Parse repository URLs
    for repo in "${reqs[@]}"; do
        if [ -z "$pat" ]; then
            parsed_required+=("https://${repo}")
        else
            parsed_required+=("https://${pat}@${repo}")
        fi
    done

    for repo in "${opts[@]}"; do
        if [ -z "$pat" ]; then
            parsed_optional+=("https://${repo}")
        else
            parsed_optional+=("https://${pat}@${repo}")
        fi
    done
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

parse_config

# Check if the localpath directory exists, create it if not
if [ ! -d "$localpath" ]; then
    if ! mkdir -p "$localpath"; then
        echo "Error! Failed to create directory: $localpath"
        exit 1
    fi
fi

# Check if required repositories exist and clone them
if [ ${#parsed_required[@]} -ne 0 ]; then
    for repo in "${parsed_required[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [ -d "$localpath$repo_name" ]; then
            echo "Repository $repo_name already exists. Skipping cloning."
        else
            echo "git clone '$repo' '$localpath$repo_name'"
            git clone "$repo" "$localpath$repo_name"
        fi
    done
fi

# Check if required repositories exist and clone them
if [ ${#parsed_optional[@]} -ne 0 ]; then
    for repo in "${parsed_optional[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [ -d "$localpath$repo_name" ]; then
            echo "Repository $repo_name already exists. Skipping cloning."
        else
            read -p "Do you want to install the repository $repo? [Y/N]: " choice
            case $choice in
                [Yy]*)
                    echo "git clone '$repo' '$localpath$repo_name'"
                    git clone "$repo" "$localpath$repo_name"
                    ;;
                *)
                    echo "Skipping installation of optional repository."
                    ;;
            esac
        fi
    done
fi
