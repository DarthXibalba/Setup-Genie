#!/bin/bash

current_user_name=$(id -un)
if [[ $current_user_name == 'root' ]]; then
    echo "This script can not be run as root."
    exit
fi

# Product info
product_name="aistudio"
phoenix_appdir="/opt/hp/${product_name}"
phoenix_bindir="${phoenix_appdir}/bin"
phoenix_etcdir="/etc/opt/hp/${product_name}"
phoenix_group=${product_name}

# containerd info
containerd_version="1.7.11"
containerd_config_dir="${phoenix_etcdir}/containerd"
containerd_config_file="config.toml"
containerd_root="/var/lib/hp/${product_name}/containerd"
containerd_state="/run/hp/${product_name}/containerd"
containerd_socket="/run/hp/${product_name}/containerd/containerd.sock"
containerd_debug_socket="/run/hp/${product_name}/containerd/debug.sock"
containerd_unit_dir="/usr/local/lib/systemd/system"
containerd_unit_file="hp-${product_name}-containerd.service"

# runc info
runc_version="1.1.10"
runc_bindir="/usr/local/sbin"

# CNI info
cni_version="1.1.1"
cni_bindir="/opt/cni/bin"

generate_containerd_conf_file() {
    phoenix_gid=$(getent group $phoenix_group | cut -d: -f3)
    sudo mkdir -p ${containerd_config_dir}
    sudo tee ${containerd_config_dir}/${containerd_config_file} > /dev/null <<- EOF
version = 2
root = "${containerd_root}"
state = "${containerd_state}"
[grpc]
    address = "${containerd_socket}"
    gid = $phoenix_gid
[debug]
    address = "${containerd_debug_socket}"
    gid = $phoenix_gid
EOF
}

generate_containerd_unit_file() {
    sudo tee ${containerd_unit_dir}/${containerd_unit_file} > /dev/null <<- EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${phoenix_bindir}/containerd -c ${containerd_config_dir}/${containerd_config_file}

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
}

sudo mkdir -p ${phoenix_appdir}

echo "Downloading and installing containerd v${containerd_version}..."
sudo sudo systemctl is-active --quiet ${containerd_unit_file}
if [[ $? -eq 0 ]]; then
    sudo systemctl stop ${containerd_unit_file}
fi
wget -q "https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-amd64.tar.gz"
sudo tar Cxzf ${phoenix_appdir} containerd-${containerd_version}-linux-amd64.tar.gz
rm containerd-${containerd_version}-linux-amd64.tar.gz

echo "Downloading and installing runc v${runc_version}..."
wget -q "https://github.com/opencontainers/runc/releases/download/v${runc_version}/runc.amd64"
sudo install -m 755 runc.amd64 ${runc_bindir}/runc
rm runc.amd64

echo "Downloading and installing CNI Plugins v${cni_version}..."
sudo mkdir -p ${cni_bindir}
wget -q "https://github.com/containernetworking/plugins/releases/download/v${cni_version}/cni-plugins-linux-amd64-v${cni_version}.tgz"
sudo tar Cxzf ${cni_bindir} "cni-plugins-linux-amd64-v${cni_version}.tgz"
rm cni-plugins-linux-amd64-v${cni_version}.tgz

echo "Creating containerd config file..."
sudo groupadd -f ${phoenix_group}
sudo usermod -a -G ${phoenix_group} ${current_user_name}
generate_containerd_conf_file

echo "Enabling containerd systemd service..."
sudo mkdir -p ${containerd_unit_dir}
generate_containerd_unit_file
sudo systemctl daemon-reload
sudo systemctl enable --now ${containerd_unit_file}

# Check if the path is already in .bashrc, add if not
if ! grep -q "${phoenix_bindir}" "${HOME}/.bashrc"; then
    echo "Adding ${phoenix_bindir} to PATH in .bashrc for user accessibility..."
    echo "export PATH=\$PATH:${phoenix_bindir}" >> "${HOME}/.bashrc"
fi

echo "Please log out and back in again to refresh your PATH and access binaries in ${phoenix_bindir}."
