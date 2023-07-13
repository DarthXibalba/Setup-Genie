#!/bin/bash

version="1.20.4"
GoURL="https://go.dev/dl/go${version}.linux-amd64.tar.gz"
GoLocal="./go${version}.linux-amd64.tar.gz"
exportLine='export PATH=$PATH:/usr/local/go/bin'

echo "Removing any previous Go installations"
sudo rm -rf /usr/local/go

echo "Downloading and installing Golang v${version}"
wget -q "${GoURL}" "${GoLocal}"
echo "Extracting the downloaded archive to /usr/local"
sudo tar -C /usr/local -xzf "${GoLocal}"

echo "Adding /usr/local/go/bin to the PATH environment variable in /etc/profile"
# Check if exportLine exists in /etc/profile
if ! grep -qF "${exportLine}" /etc/profile; then
    echo "${exportLine}" | sudo tee -a /etc/profile > /dev/null
fi

rm -f "${GoLocal}"
echo -e "Please log out & log back in (or restart your system) to apply changes"
echo -e "Then verify the installation by running the following: \n $ go version"
