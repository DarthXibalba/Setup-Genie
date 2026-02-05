#!/bin/bash
set -euo pipefail

# -----------------------------
# Paths
# -----------------------------
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
config_file="$script_dir/../config/gitconfig.json"

# -----------------------------
# Helpers
# -----------------------------
usage() {
    echo "Usage: $0 [$(printf "%s | " "${valid_flags[@]}" | sed 's/ | $//')]"
    exit 1
}

copy_to_clipboard() {
    if command -v wl-copy &>/dev/null; then
        wl-copy < "$ssh_pub"
        echo "Public key copied to clipboard (wl-copy)"
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard < "$ssh_pub"
        echo "Public key copied to clipboard (xclip)"
    else
        echo "Clipboard utility not found; printing key instead:"
        cat "$ssh_pub"
    fi
}

# -----------------------------
# Validate config file
# -----------------------------
[[ -f "$config_file" ]] || {
    echo "Error: config file not found: $config_file"
    exit 1
}

# -----------------------------
# Detect valid profiles dynamically
# -----------------------------
mapfile -t valid_flags < <(jq -r 'keys[]' "$config_file")

if [[ ${#valid_flags[@]} -eq 0 ]]; then
    echo "Error: No profiles found in $config_file"
    exit 1
fi

# -----------------------------
# Argument parsing
# -----------------------------
[[ $# -eq 1 ]] || usage
profile="$1"

if [[ ! " ${valid_flags[*]} " =~ " ${profile} " ]]; then
    usage
fi

# -----------------------------
# Install dependencies
# -----------------------------
$apt_get_install git jq openssh-client

# Optional clipboard helpers (best-effort)
sudo apt-get install -y wl-clipboard xclip >/dev/null 2>&1 || true

# -----------------------------
# Read config values
# -----------------------------
username="$(jq -r ".${profile}.USERNAME // empty" "$config_file")"
email="$(jq -r ".${profile}.EMAIL // empty" "$config_file")"
localpath="$(jq -r ".${profile}.LOCALPATH // empty" "$config_file")"

if [[ -z "$username" || -z "$email" ]]; then
    echo "Error: USERNAME or EMAIL missing in [$profile] config"
    exit 1
fi

if [[ -z "$localpath" ]]; then
    echo "Error: LOCALPATH missing in [$profile] config"
    exit 1
fi

# -----------------------------
# Configure git (user-level only)
# -----------------------------
git config --global user.name "$username"
git config --global user.email "$email"
git config --global init.defaultBranch main

echo "Git configured:"
git config --global --list | grep -E 'user.name|user.email|init.defaultBranch'

# -----------------------------
# Create LOCALPATH
# -----------------------------
expanded_localpath="$(eval echo "$localpath")"
mkdir -p "$expanded_localpath"
chmod 755 "$expanded_localpath"

echo "Workspace directory ensured: $expanded_localpath"

# -----------------------------
# SSH key setup (per-profile)
# -----------------------------
ssh_key="$HOME/.ssh/id_ed25519_${profile}"
ssh_pub="${ssh_key}.pub"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$ssh_key" && -f "$ssh_pub" ]]; then
    echo "Existing SSH key found: $ssh_key"
else
    echo "No SSH key found — generating new ed25519 key for profile '$profile'"
    ssh-keygen -t ed25519 -C "$email" -f "$ssh_key" -N ""
fi

# -----------------------------
# SSH agent
# -----------------------------
if ! pgrep -u "$USER" ssh-agent &>/dev/null; then
    eval "$(ssh-agent -s)"
fi

ssh-add "$ssh_key" >/dev/null 2>&1 || true

# -----------------------------
# SSH config (profile-aware)
# -----------------------------
ssh_config="$HOME/.ssh/config"
touch "$ssh_config"
chmod 600 "$ssh_config"

if ! grep -q "Host github.com-${profile}" "$ssh_config"; then
    cat >> "$ssh_config" <<EOF

Host github.com-${profile}
    HostName github.com
    User git
    IdentityFile $ssh_key
    IdentitiesOnly yes
EOF

    echo "SSH config entry added: github.com-${profile}"
else
    echo "SSH config entry already exists: github.com-${profile}"
fi

# -----------------------------
# Output public key
# -----------------------------
echo
echo "====== SSH PUBLIC KEY (${profile}) ======"
copy_to_clipboard
echo
echo "Add this key to GitHub:"
echo "https://github.com/settings/ssh/new"
echo
echo "Use this host when cloning:"
echo "git clone git@github.com-${profile}:ORG/REPO.git"
echo "========================================="
