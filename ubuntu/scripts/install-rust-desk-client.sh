#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

version="1.4.3"
arch="x86_64"
rustPath="/tmp/rustdesk-$version-$arch.deb"
rustURL="https://github.com/rustdesk/rustdesk/releases/download/$version/rustdesk-$version-$arch.deb"

# Download
$wget_download $rustURL $rustPath
# Install
$apt_get_install $rustPath

