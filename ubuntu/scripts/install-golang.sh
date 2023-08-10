#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
wget_download="$script_dir/helper_scripts/wget-download.sh"

# Variables
version="1.20.4"
GoURL="https://go.dev/dl/go${version}.linux-amd64.tar.gz"
GoPath="$script_dir/../setup-files/go${version}.linux-amd64.tar.gz"

# Remove previous installations
echo "Removing any previous Go installations"
sudo rm -rf /usr/local/go

# Download
echo "Downloading and installing Golang v${version}"
$wget_download $GoURL $GoPath

# Extract
echo "Extracting the downloaded archive to /usr/local"
sudo tar -C /usr/local -xzf "${GoPath}"

# Set PATH variable
echo "Adding /usr/local/go/bin to the PATH environment variable in /etc/profile"
# Check if exportLine exists in /etc/profile
exportLine='export PATH=$PATH:/usr/local/go/bin'
if ! grep -qF "${exportLine}" /etc/profile; then
    echo "${exportLine}" | sudo tee -a /etc/profile > /dev/null
fi

echo -e "Please log out & log back in (or restart your system) to apply changes"
echo -e "Then verify the installation by running the following: \n $ go version"
