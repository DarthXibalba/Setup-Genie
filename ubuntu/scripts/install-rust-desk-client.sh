#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper_scripts/apt-get-install.sh"
wget_download="$script_dir/helper_scripts/wget-download.sh"

# Download the RustDesk Software
version="1.1.8"
rustPath="$script_dir/../setup-files/rustdesk-"$version".deb"
rustURL="https://github.com/rustdesk/rustdesk/releases/download/"$version"/rustdesk-"$version".deb"
$wget_download $rustURL $rustPath

# Install the RustDesk Software
sudo apt-get install $rustPath

