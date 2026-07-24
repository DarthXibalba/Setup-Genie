#!/bin/bash
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

bashrcd_dir="$HOME/.bashrc.d"
bashrcd_file="$bashrcd_dir/setup-genie-aliases.sh"

read -r -d '' alias_content <<'EOF' || true
alias gitadd='git add'
alias gitcommit='git commit -m'
alias gitdiff='git diff'
alias gitlog='git log'
alias gitpull='git pull'
alias gitpullorigin='git pull origin'
alias gitpulloriginmain='git pull origin main'
alias gitpushorigin='git push'
alias gitpushoriginmain='git push origin main'
alias gitstatus='git status'
alias la='ls -lah'
EOF

mkdir -p "$bashrcd_dir"

cat > "$bashrcd_file" <<EOF
# Setup-Genie managed aliases
$alias_content
EOF

chmod 644 "$bashrcd_file"

log_success "Wrote Setup-Genie aliases to $bashrcd_file"
log_success "Bash profile setup complete"
