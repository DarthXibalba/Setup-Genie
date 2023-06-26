#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 [--personal | --work | --containerd]"
}

# Function to parse the gitconfig.json file and return required repos
parse_required_repos() {
    local config_file=$1
    local config_section=$2

    local required_key="REQUIRED"
    local pat_key="PAT"

    # Read the required repositories into an array
    readarray -t required_repos < <(jq -r ".${config_section}.${required_key}[]" "$config_file")

    # Read the PAT value
    pat=$(jq -r ".${config_section}.${pat_key}" "$config_file")

    # Parse repository URLs
    parsed_required_repos=()

    for repo in "${required_repos[@]}"; do
        if [ -z "$pat" ]; then
            parsed_required_repos+=("https://${repo}")
        else
            parsed_required_repos+=("https://${pat}@${repo}")
        fi
    done

    # Return the parsed array
    echo "${parsed_required_repos[@]}"
}

# Function to parse the gitconfig.json file and return optional repos
parse_optional_repos() {
    local config_file=$1
    local config_section=$2

    local optional_key="OPTIONAL"
    local pat_key="PAT"

    # Read the optional repositories into an array
    readarray -t optional_repos < <(jq -r ".${config_section}.${optional_key}[]" "$config_file")

    # Read the PAT value
    pat=$(jq -r ".${config_section}.${pat_key}" "$config_file")

    # Parse repository URLs
    parsed_optional_repos=()

    for repo in "${optional_repos[@]}"; do
        if [ -z "$pat" ]; then
            parsed_optional_repos+=("https://${repo}")
        else
            parsed_optional_repos+=("https://${pat}@${repo}")
        fi
    done

    # Return the parsed array
    echo "${parsed_optional_repos[@]}"
}


# Function to parse the gitconfig.json file and return the localpath
parse_localpath() {
    local config_file=$1
    local config_section=$2

    local localpath_key="LOCALPATH"

    # Read the localpath value
    localpath=$(jq -r ".${config_section}.${localpath_key}" "$config_file")

    # Remove leading and trailing double quotes from value
    localpath=$(eval "echo $(sed 's/^"\(.*\)"$/\1/' <<< "$localpath")")

    # Print the parsed value
    echo "$localpath"
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
        --containerd)
        config_section="containerd"
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
config_file="./config/gitconfig_template.json"

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

# Read from config_file
localpath=$(parse_localpath "$config_file" "$config_section")
parsed_required_repos=$(parse_required_repos "$config_file" "$config_section")
parsed_optional_repos=$(parse_optional_repos "$config_file" "$config_section")

# Check if the localpath directory exists, create it if not
if [ ! -d "$localpath" ]; then
    if ! mkdir -p "$localpath"; then
        echo "Error! Failed to create directory: $localpath"
        exit 1
    fi
fi

# Change to the specified localpath directory
if ! cd "$localpath"; then
    echo "Error! Failed to change directory to $localpath"
    exit 1
fi

# Check if required repositories exist and clone them
if [ ${#parsed_required_repos[@]} -ne 0 ]; then
    for repo in "${parsed_required_repos[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [ -d "$localpath$repo_name" ]; then
            echo "Repository $repo_name already exists. Skipping cloning."
        else
            echo "git clone '$repo' '$localpath$repo_name'"
            git clone "$repo" "$localpath$repo_name"
        fi
    done
fi

# Check if optional repositories exist and prompt for installation
if [ ${#parsed_optional_repos[@]} -ne 0 ]; then
    for repo in "${parsed_optional_repos[@]}"; do
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
                    echo "Skipping installation of optional repository $repo."
                    ;;
            esac
        fi
    done
fi
