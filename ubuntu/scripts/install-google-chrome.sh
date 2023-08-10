#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper_scripts/apt-get-install.sh"
wget_download="$script_dir/helper_scripts/wget-download.sh"

# Download Google Chrome deb
gChromePath="$script_dir/../setup-files/google-chrome-stable_current_amd64.deb"
gChromeURL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
$wget_download $gChromeURL $gChromePath

# Install the Google Chrome deb
$apt_get_install $gChromePath
