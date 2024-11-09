#!/bin/bash
script_dir="$(dirname "$(realpath "$0")")"
write_text_sh="$script_dir/../helper-scripts/write-text-line-in-file.sh"
hooh_file="$HOME/.hooh"

declare config_file="$script_dir/../config/gitconfig.json"
declare config_section="work"

# Function to read PAT from config file
key_pat="PAT"
pat_token=$(jq -r ".${config_section}.${key_pat}" "$config_file")
if [ -z "${pat_token}" ]; then
    echo "Error! Invalid config file: Missing PAT in [$config_section] section."
    exit 1
fi

# Create file if it doesn't exist
if [ ! -f "$hooh_file" ]; then
    touch "$hooh_file"
fi

$write_text_sh "$hooh_file" "GITHUB_TOKEN: $pat_token"
$write_text_sh "$hooh_file" " "
