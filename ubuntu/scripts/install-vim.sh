#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Install dependencies
$script_dir"/apt-get-install.sh" vim
