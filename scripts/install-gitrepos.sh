#!/bin/bash

# Function to display script usage
display_usage() {
    echo "Usage: $0 [--personal | --work | --containerd]"
}

# Declare global variables
declare config_file="./config/gitconfig_template.json"
declare localpath
declare -a parsed_required
declare -a parsed_optional

# Function to parse the gitconfig.json file and return localpath, required repos, and optional repos
parse_config() {
    local config_section=$1

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

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error! Config file not found: $config_file"
    display_usage
    exit 1
fi

parse_config "$config_section"

echo "[DEBUG] localpath (global): $localpath"
echo "[DEBUG] pat (global): $pat"
echo "[DEBUG] reqs (global): $reqs"
echo "[DEBUG] opts (global): $opts"
echo "[DEBUG] parsed_required (global): ${parsed_required[@]}"
echo "[DEBUG] parsed_optional (global): ${parsed_optional[@]}"