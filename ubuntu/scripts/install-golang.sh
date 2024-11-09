#!/bin/bash

if [[ $(id -u) -eq 0 ]]; then
    echo "This script can not be run as root."
    exit
fi

go_version="1.22.3"
go_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
go_file="./go${go_version}.linux-amd64.tar.gz"
go_root="/usr/local"
go_dir="${go_root}/go"
go_bindir="${go_dir}/bin"
go_export_line='export PATH=$PATH:'${go_bindir}

echo "Removing any previous Go installations"
sudo rm -rf ${go_dir}

echo "Downloading and installing Golang v${go_version}"
wget -q "${go_url}" "${go_file}"
sudo tar -C ${go_root} -xzf "${go_file}"

rm -f "${go_file}"

# Check if go_export_line exists in /etc/profile, if not, add it.
if ! grep -qF "${go_export_line}" /etc/profile; then
    echo "Adding ${go_bindir} to the PATH environment variable in /etc/profile"
    echo "${go_export_line}" | sudo tee -a /etc/profile > /dev/null
    echo -e "Please log out & log back in (or restart your system) to apply changes"
    echo -e "Then verify the installation by running the following: \n $ go version"
fi
