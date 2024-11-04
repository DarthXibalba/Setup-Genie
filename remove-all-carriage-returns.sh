#!/bin/bash
### Run the following to convert this script:
## tr -d '\r' < remove-all-carriage-returns.sh > remove-all-carriage-returns2.sh
## mv remove-all-carriage-returns2.sh remove-all-carriage-returns.sh
## chmod +x remove-all-carriage-returns.sh

script_dir=$(dirname "$(realpath "$0")")
src_dir="$script_dir/ubuntu"
dst_dir="$script_dir/ubuntu-converted"

subDirsToTrim=("config" "helper-scripts" "profile" "scripts")

idx=0
filesSrc[idx]="$src_dir/setup.sh"
filesDst[idx]="$dst_dir/setup.sh"

# Add files in each subdirectory to filesToTrim
for subDir in "${subDirsToTrim[@]}"; do
    subDirPathSrc="$src_dir/$subDir"
    subDirPathDst="$dst_dir/$subDir"
    
    # Find all files in the subdirectory and append to arrays
    while IFS= read -r -d '' file; do
        filesSrc[++idx]="$file"
        filesDst[idx]="${file/$src_dir/$dst_dir}"
    done < <(find "$subDirPathSrc" -type f -print0)
done

# Create destination directories
if [ -d "$dst_dir" ]; then
    rm -rf "$dst_dir"
fi

mkdir -p "$dst_dir"
for subDir in "${subDirsToTrim[@]}"; do
    mkdir -p "$dst_dir/$subDir"
done

# Trim each file
for (( i=0; i<=idx; i++ )); do
    tr -d '\r' < "${filesSrc[$i]}" > "${filesDst[$i]}"
    if [[ "${filesDst[$i]}" == *.sh ]]; then
        chmod +x "${filesDst[$i]}"
    fi
done
