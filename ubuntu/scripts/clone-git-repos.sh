#!/bin/bash
set -euo pipefail

# -----------------------------
# Paths
# -----------------------------
script_dir="$(dirname "$(realpath "$0")")"
config_file="$script_dir/../config/gitconfig.json"

# -----------------------------
# Helpers
# -----------------------------
usage() {
    echo "Usage: $0 [$(printf "%s | " "${valid_flags[@]}" | sed 's/ | $//')]"
    exit 1
}

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

repo_dir_name() {
    basename "$1" .git
}

# -----------------------------
# Validate config
# -----------------------------
[[ -f "$config_file" ]] || {
    echo "Error: config file not found: $config_file"
    exit 1
}

# -----------------------------
# Detect valid profiles
# -----------------------------
mapfile -t valid_flags < <(jq -r 'keys[]' "$config_file")

[[ ${#valid_flags[@]} -gt 0 ]] || {
    echo "Error: No profiles found in config"
    exit 1
}

# -----------------------------
# Argument parsing
# -----------------------------
[[ $# -eq 1 ]] || usage
profile="$1"

if [[ ! " ${valid_flags[*]} " =~ " ${profile} " ]]; then
    usage
fi

# -----------------------------
# Read config values
# -----------------------------
username="$(jq -r ".${profile}.USERNAME // empty" "$config_file")"
email="$(jq -r ".${profile}.EMAIL // empty" "$config_file")"
localpath="$(jq -r ".${profile}.LOCALPATH // empty" "$config_file")"

mapfile -t required_repos < <(jq -r ".${profile}.REQUIRED[]? // empty" "$config_file")
mapfile -t optional_repos < <(jq -r ".${profile}.OPTIONAL[]? // empty" "$config_file")

if [[ -z "$username" || -z "$email" || -z "$localpath" ]]; then
    echo "Error: USERNAME, EMAIL, or LOCALPATH missing in [$profile] config"
    exit 1
fi

# -----------------------------
# Prepare workspace
# -----------------------------
expanded_localpath="$(eval echo "$localpath")"
mkdir -p "$expanded_localpath"
cd "$expanded_localpath"

echo "Using workspace: $expanded_localpath"
echo

# -----------------------------
# Clone function
# -----------------------------
clone_repo() {
    local repo="$1"
    local dir
    dir="$(repo_dir_name "$repo")"

    if [[ -d "$dir/.git" ]]; then
        echo "Skipping (already cloned): $repo"
        return
    fi

    echo "Cloning: $repo"
    git clone "$repo"

    pushd "$dir" >/dev/null
    git config user.name "$username"
    git config user.email "$email"
    popd >/dev/null

    echo "Configured repo-local git identity for $dir"
}

# -----------------------------
# Clone REQUIRED repos
# -----------------------------
if [[ ${#required_repos[@]} -gt 0 ]]; then
    echo "Cloning REQUIRED repositories"
    for repo in "${required_repos[@]}"; do
        clone_repo "$repo"
    done
    echo
fi

# -----------------------------
# Prompt for OPTIONAL repos
# -----------------------------
if [[ ${#optional_repos[@]} -gt 0 ]]; then
    echo "Optional repositories:"
    for repo in "${optional_repos[@]}"; do
        if confirm "Clone $repo?"; then
            clone_repo "$repo"
        else
            echo "Skipped: $repo"
        fi
    done
fi

echo
echo "Repository cloning complete."
