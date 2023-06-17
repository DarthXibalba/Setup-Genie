#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Copy profile
cp "$script_dir/../setup-files/profile/.bashrc" "$HOME/.bashrc"
cp "$script_dir/../setup-files/profile/.bash_aliases" "$HOME/.bash_aliases"

echo "Copied bash profile. Please run $ source ~/.bashrc to reload profile"
