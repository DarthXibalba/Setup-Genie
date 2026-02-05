#!/bin/bash
set -euo pipefail

# -----------------------------
# Paths
# -----------------------------
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
config_file="$script_dir/../config/gitconfig.json"

# -----------------------------
# Config
# -----------------------------
valid_flags=("personal" "work" "containerd")
ssh_key="$HOME/.ssh/id_ed25519"
ssh_pub="${ssh_key}.pub"

# -----------------------------
# Helpers
# -----------------------------
usage() {
    echo "Usage: $0 [${valid_flags[*]}]"
    exit 1
}

require_cmd() {
    command -v "$1" &>/dev/null || {
        echo "Error: required command '$1' not found"
        exit 1
    }
}

copy_to_clipboard() {
    if command -v wl-copy &>/dev/null; then
        wl-copy < "$ssh_pub"
        echo "Public key copied to clipboard (wl-copy)"
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard < "$ssh_pub"
        echo "Public key copied to clipboard (xclip)"
    else
        echo "Clipboard utility not found; printing key instead"
        cat "$ssh_pub"
    fi
}

# -----------------------------
# Argument parsing
# -----------------------------
[[ $# -eq 1 ]] || usage
profile="$1"

if [[ ! " ${valid_flags[*]} " =~ " ${profile} " ]]; then
    usage
fi

[[ -f "$config_file" ]] || {
    echo "Error: config file not found: $config_file"
    exit 1
}

# -----------------------------
# Install dependencies
# -----------------------------
$apt_get_install git jq openssh-client

# Optional clipboard tools (best-effort)
sudo apt-get install -y wl-clipboard xclip 2>/dev/null || true

# -----------------------------
# Read config
# -----------------------------
username="$(jq -r ".${profile}.USERNAME // empty" "$config_file")"
email="$(jq -r ".${profile}.EMAIL // empty" "$config_file")"

if [[ -z "$username" || -z "$email" ]]; then
    echo "Error: USERNAME or EMAIL missing in [$profile] config"
    exit 1
fi

# -----------------------------
# Configure git
# -----------------------------
git config --global user.name "$username"
git config --global user.email "$email"
git config --global init.defaultBranch main

echo "Git configured:"
git config --global --list | grep -E 'user.name|user.email|init.defaultBranch'

# -----------------------------
# SSH key setup
# -----------------------------
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$ssh_key" && -f "$ssh_pub" ]]; then
    echo "Existing SSH key found: $ssh_key"
else
    echo "No SSH key found — generating new ed25519 key"
    ssh-keygen -t ed25519 -C "$email" -f "$ssh_key" -N ""
fi

# -----------------------------
# SSH agent
# -----------------------------
if ! pgrep -u "$USER" ssh-agent &>/dev/null; then
    eval "$(ssh-agent -s)"
fi

ssh-add "$ssh_key" 2>/dev/null || true

# -----------------------------
# Output public key
# -----------------------------
echo
echo "====== SSH PUBLIC KEY ======"
copy_to_clipboard
echo
echo "Add this key to GitHub:"
echo "https://github.com/settings/ssh/new"
echo "============================"
