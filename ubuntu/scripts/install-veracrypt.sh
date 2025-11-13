#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

version="1.26.24"
osarch="Ubuntu-22.04-amd64"
downloadPath="/tmp/veracrypt-$version-$osarch.deb"
url="https://launchpad.net/veracrypt/trunk/$version/+download/veracrypt-$version-$osarch.deb"

# Download
$wget_download $url $downloadPath
# Install
$apt_get_install $downloadPath
