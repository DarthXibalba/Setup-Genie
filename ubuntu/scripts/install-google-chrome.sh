#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Download Google Chrome deb
gChromePath="$script_dir/../setup-files/google-chrome-stable_current_amd64.deb"
gChromeURL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
if [ ! -f "$gChromePath" ]; then
    echo "downloading "$gChromeURL
    sudo wget "$gChromeURL"
fi

# Install the Google Chrome deb
sudo apt-get install $gChromePath -y
