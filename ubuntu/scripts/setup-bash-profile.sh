#!/bin/bash

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
profile_dir="$script_dir/../profile"
rm_carriage_rtn="$script_dir/../helper-scripts/remove-carriage-returns.sh"

idx=0
filesSrc=()
filesTmp=()
filesDst=()
tmp_dir="$profile_dir/tmp"
dst_dir="$HOME"

# Check if the profile directory exists
if [ ! -d "$profile_dir" ]; then
    echo "Error: Profile directory does not exist at $profile_dir"
    exit 1
fi

# Loop through all files in profile_dir and add to filesSrc and filesDst
while IFS= read -r -d '' file; do
    filesSrc[idx]="$file"
    filesTmp[idx]="${file/$profile_dir/$tmp_dir}"
    filesDst[idx]="${file/$profile_dir/$dst_dir}"
    ((idx++))
done < <(find "$profile_dir" -type f -print0)

# Remove carriage return artifacts due to cross-platform (Windows) development
mkdir "$tmp_dir"
for ((i = 0; i < ${#filesSrc[@]}; i++)); do
    echo "$rm_carriage_rtn ${filesSrc[i]} ${filesTmp[i]}"
    "$rm_carriage_rtn" "${filesSrc[i]}" "${filesTmp[i]}"
done

# Move profile files to $HOME
for ((i = 0; i < ${#filesTmp[@]}; i++)); do
    echo "mv ${filesTmp[i]} ${filesDst[i]}"
    mv "${filesTmp[i]}" "${filesDst[i]}"
done

# Cleanup and exit
rm -rf "$tmp_dir"
echo "Deleted $tmp_dir"
echo "Copied bash profile."
echo "Please run $ source ~/.bashrc to reload profile"
