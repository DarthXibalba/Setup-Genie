#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"

$apt_get_install python3 python3-pip python3-venv
