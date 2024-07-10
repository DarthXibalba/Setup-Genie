#!/bin/bash

if [[ $(id -u) -eq 0 ]]; then
    echo "This script can not be run as root."
    exit
fi

nerdctl_version="1.7.3"
nerdctl_file="nerdctl-${nerdctl_version}-linux-amd64.tar.gz"
nerdctl_url="https://github.com/containerd/nerdctl/releases/download/v${nerdctl_version}/nerdctl-${nerdctl_version}-linux-amd64.tar.gz"
nerdctl_bindir="/usr/local/bin"

echo "Downloading and installing nerdctl v${nerdctl_version}"
wget -q "${nerdctl_url}" "${nerdctl_file}"

echo "Extracting to ${nerdctl_bindir}"
sudo tar -C "${nerdctl_bindir}" -xzf "${nerdctl_file}"

rm -f "${nerdctl_file}"
