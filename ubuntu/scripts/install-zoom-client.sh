#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

# Download the RustDesk Software
version="6.2.6.2503"
zoomPath="/tmp/zoom_amd64.deb"
zoomURL="https://zoom.us/client/$version/zoom_amd64.deb"
$wget_download $rustURL $rustPath

# Install the RustDesk Software
sudo apt-get install $rustPath

