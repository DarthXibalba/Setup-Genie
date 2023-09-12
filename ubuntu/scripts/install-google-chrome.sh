#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper_scripts/apt-get-install.sh"

# Install the Google Chrome
$apt_get_install google-chrome-stable
