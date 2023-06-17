#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 [--personal | --work | --containerd]"
}

# Function to parse the gitconfig.ini file
parse_gitconfig() {
    local config_file=$1
    local config_section=$2
    local required_key="REQUIRED"
    local optional_key="OPTIONAL"

    # Read the required repositories
    readarray -t required_repos < <(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /${required_key}\[]/{print \$2}" "$config_file" | awk '{$1=$1};1')

    # Read the optional repositories
    readarray -t optional_repos < <(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /${optional_key}\[]/{print \$2}" "$config_file" | awk '{$1=$1};1')

    # Remove leading and trailing double quotes from repository URLs
    for ((i=0; i<${#required_repos[@]}; i++)); do
        required_repos[i]=$(sed 's/^"\(.*\)"$/\1/' <<< "${required_repos[i]}")
    done

    for ((i=0; i<${#optional_repos[@]}; i++)); do
        optional_repos[i]=$(sed 's/^"\(.*\)"$/\1/' <<< "${optional_repos[i]}")
    done

    # Read LOCALPATH and PAT values
    localpath=$(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /LOCALPATH/{print \$2}" "$config_file" | awk '{$1=$1};1')
    pat=$(awk -F "=" "/\[${config_section}\]/{flag=1; next} /\[/{flag=0} flag && /PAT/{print \$2}" "$config_file" | awk '{$1=$1};1')

    # Remove leading and trailing double quotes from LOCALPATH and PAT values
    localpath=$(eval "echo $(sed 's/^"\(.*\)"$/\1/' <<< "$localpath")")
    pat=$(sed 's/^"\(.*\)"$/\1/' <<< "$pat")

    # Parse repository URLs
    parsed_required_repos=()
    parsed_optional_repos=()

    for repo in "${required_repos[@]}"; do
        if [ -z "$pat" ]; then
            parsed_required_repos+=("https://${repo}")
        else
            parsed_required_repos+=("https://${pat}@${repo}")
        fi
    done

    for repo in "${optional_repos[@]}"; do
        if [ -z "$pat" ]; then
            parsed_optional_repos+=("https://${repo}")
        else
            parsed_optional_repos+=("https://${pat}@${repo}")
        fi
    done

    # Print the parsed values
    echo "${parsed_required_repos[@]}"
    echo "${parsed_optional_repos[@]}"
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
config_file="gitconfig.ini"

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

# Parse the gitconfig.ini file
parse_result=$(parse_gitconfig "$config_file" "$config_section")
parse_successful=$?

# Check if parsing was successful
if [ $parse_successful -ne 0 ]; then
    echo "Error! Failed to parse gitconfig.ini file."
    exit 1
fi

# Assign the parsed values
readarray -t parsed_required_repos <<< "${parse_result[0]}"
readarray -t parsed_optional_repos <<< "${parse_result[1]}"
localpath="${parse_result[2]}"

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
        if [ -d "$repo_name" ]; then
            echo "Repository $repo_name already exists. Skipping cloning."
        else
            git clone "$repo" "$localpath/$repo_name"
        fi
    done
fi

# Check if optional repositories exist and prompt for installation
if [ ${#parsed_optional_repos[@]} -ne 0 ]; then
    # Prompt user for optional repositories installation
    for repo in "${parsed_optional_repos[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [ -d "$repo_name" ]; then
            echo "Repository $repo_name already exists. Skipping cloning."
        else
            read -p "Do you want to install the repository $repo? [Y/N]: " choice
            case $choice in
                [Yy]*)
                    git clone "$repo" "$localpath/$repo_name"
                    ;;
                *)
                    echo "Skipping installation of optional repository $repo."
                    ;;
            esac
        fi
    done
fi

