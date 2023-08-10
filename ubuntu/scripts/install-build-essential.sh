#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Install dependencies
$script_dir"/helper_scripts/apt-get-install.sh" build-essential
