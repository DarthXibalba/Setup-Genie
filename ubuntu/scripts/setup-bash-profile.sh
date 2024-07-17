#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
profile_dir="$script_dir/../profile"
rm_carriage_rtn="$script_dir/../helper-scripts/remove-carriage-returns.sh"

# List of files to process
files=(
  ".bashrc"
  ".bash_aliases"
  ".conda_aliases"
  ".golang_phoenix_aliases"
  ".nerdctl_phoenix_aliases"
)

# Remove carriage return artifacts due to cross-platform (Windows) development
temp_dir="$profile_dir/tmp"
mkdir "$temp_dir"

for file in "${files[@]}"; do
  source_file="$profile_dir/$file"
  target_file="$temp_dir/$file"
  "$rm_carriage_rtn" "$source_file" "$target_file"
done

# Move profile files to $HOME
for file in "${files[@]}"; do
  source_file="$temp_dir/$file"
  target_file="$HOME/$file"
  mv "$source_file" "$target_file"
done

# Cleanup and exit
rm -rf "$temp_dir"
echo "Deleted $temp_dir"
echo "Copied bash profile."
echo "Please run $ source ~/.bashrc to reload profile"
