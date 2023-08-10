#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper_scripts/apt-get-install.sh"

# Install dependencies
$apt_get_install build-essential
