#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
profile_dir="$script_dir/../profile"

# Copy profile
cp "$profile_dir/.bashrc" "$HOME/.bashrc"
cp "$profile_dir/.bash_aliases" "$HOME/.bash_aliases"
cp "$profile_dir/.conda_aliases" "$HOME/.conda_aliases"
cp "$profile_dir/.golang_phoenix_aliases" "$HOME/.golang_phoenix_aliases"
cp "$profile_dir/.nerdctl_phoenix_aliases" "$HOME/.nerdctl_phoenix_aliases"

echo "Copied bash profile. Please run $ source ~/.bashrc to reload profile"
