#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

# Download the Zoom
version="6.2.6.2503"
zoomPath="/tmp/zoom_amd64.deb"
zoomURL="https://zoom.us/client/$version/zoom_amd64.deb"
$wget_download $zoomURL $zoomPath

# Install the Zoom
$apt_get_install $zoomPath

