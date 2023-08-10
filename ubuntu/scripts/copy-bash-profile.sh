#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Copy profile
cp "$script_dir/../profile/.bashrc" "$HOME/.bashrc"
cp "$script_dir/../profile/.bash_aliases" "$HOME/.bash_aliases"
cp "$script_dir/../profile/.conda_aliases" "$HOME/.conda_aliases"
cp "$script_dir/../profile/.golang_phoenix_aliases" "$HOME/.golang_phoenix_aliases"
cp "$script_dir/../profile/.nerdctl_phoenix_aliases" "$HOME/.nerdctl_phoenix_aliases"

echo "Copied bash profile. Please run $ source ~/.bashrc to reload profile"
