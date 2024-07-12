#!/bin/bash

if [ $# -eq 0 ]; then
    echo "This script installs whatever packages are specified as a command arguments"
    echo "Usage: $0 <package_name1> <package_name2> ..."
    exit 1
fi

for package_name in "$@"; do
    if ! command -v "$package_name" &> /dev/null; then
        echo "$package_name is not installed, installing..."
        sudo apt-get update
        sudo apt-get install "$package_name" -y
    else
        echo "$package_name is already installed."
    fi
done
