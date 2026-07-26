#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — prepare an Ansible CONTROL NODE for Setup-Genie
# =============================================================================
# Installs ansible-core (isolated via pipx) plus the pinned Galaxy collections
# from ansible/requirements.yml. Run this ONCE on the machine you will drive
# Ansible FROM (your control node). Idempotent — safe to re-run.
#
# Usage:  bash bootstrap/bootstrap.sh
# =============================================================================
set -euo pipefail

# --- tiny standalone logger (repo helpers may be absent on a fresh box) -------
c_reset='\033[0m'; c_blue='\033[0;34m'; c_green='\033[0;32m'
c_yellow='\033[0;33m'; c_red='\033[0;31m'
log()  { echo -e "${c_blue}==>${c_reset} $*"; }
ok()   { echo -e "${c_green}[OK]${c_reset} $*"; }
warn() { echo -e "${c_yellow}[WARN]${c_reset} $*"; }
err()  { echo -e "${c_red}[ERROR]${c_reset} $*" >&2; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
requirements_file="$repo_root/ansible/requirements.yml"

# --- 1. system prerequisites --------------------------------------------------
if ! command -v apt-get >/dev/null 2>&1; then
    err "This bootstrap targets Debian/Ubuntu (apt-get not found)."
    exit 1
fi

log "Installing system prerequisites (python3, pipx, git, openssh-client)..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip pipx git openssh-client

# --- 2. ensure pipx-installed apps are on PATH --------------------------------
pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"

# --- 3. install ansible-core (idempotent) -------------------------------------
if command -v ansible >/dev/null 2>&1; then
    ok "Ansible already installed ($(ansible --version | head -n1))."
else
    log "Installing ansible-core via pipx..."
    pipx install ansible-core
    ok "ansible-core installed."
fi

# --- 4. install pinned Galaxy collections -------------------------------------
if [ ! -f "$requirements_file" ]; then
    err "requirements.yml not found at: $requirements_file"
    exit 1
fi
log "Installing Galaxy collections from requirements.yml..."
ansible-galaxy collection install -r "$requirements_file"
ok "Collections installed."

# --- 5. next steps ------------------------------------------------------------
ok "Control node ready."
log "Next steps:"
echo "  1. cd $repo_root/ansible"
echo "  2. Smoke test:    ansible -m ping all"
echo "  3. Run scaffold:  ansible-playbook site.yml"
echo "  4. Add remote targets under 'workstations' in inventory/hosts.yml"
warn "If 'ansible' is still not found, open a new shell — pipx updated your PATH."
