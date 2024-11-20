#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
wget_download="$script_dir/../helper-scripts/wget-download.sh"

awscliPath="/tmp/awscliv2.zip"
awscliURL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
$wget_download "$awscliURL" "$awscliPath"
unzip "$awscliPath" -d /tmp/
sudo /tmp/aws/install
