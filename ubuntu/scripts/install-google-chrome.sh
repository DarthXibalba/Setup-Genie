#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

# Install the Google Chrome
##$apt_get_install google-chrome-stable

gChromePath="/tmp/google-chrome-stable_current_amd64.deb"
gChromeURL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
$wget_download "$gChromeURL" "$gChromePath"
sudo dpkg -i "$gChromePath"

# If dependency errors occur run the following:
# sudo apt --fix-broken install
