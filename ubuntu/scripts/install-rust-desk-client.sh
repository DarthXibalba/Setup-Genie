#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Download the RustDesk Software
version="1.1.8"
rustPath="$script_dir/../setup-files/rustdesk-"$version".deb"
rustURL="https://github.com/rustdesk/rustdesk/releases/download/"$version"/rustdesk-"$version".deb"
if [ ! -f "$rustPath" ]; then
    echo "downloading "$rustURL
    sudo wget "$rustURL" "$rustPath"
fi

# Install the RustDesk Software
$script_dir"/helper_scripts/apt-get-install.sh" $rustPath
