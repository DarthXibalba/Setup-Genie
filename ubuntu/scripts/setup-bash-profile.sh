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

bash_aliases_file="$HOME/.bash_aliases"

read -r -d '' alias_content <<'EOF' || true
# Setup-Genie managed aliases
alias gitadd='git add'
alias gitbranch='git branch'
alias gitcheckout='git checkout'
alias gitcommit='git commit -m'
alias gitdiff='git diff'
alias gitfetch='git fetch'
alias gitfetchoriginprune='git fetch origin -p'
alias gitlog='git log'
alias gitpull='git pull'
alias gitpush='git push'
alias gitstatus='git status'
# CNCF
alias awscheckloginstatus='aws sts get-caller-identity'
alias ghcheckloginstatus='gh auth status'
# Misc
alias la='ls -lah'
alias makelist="make -qp | awk -F':' '/^[a-zA-Z0-9][^#\/\t=]*:([^=]|\$)/ {split(\$1,A,/ /); for(i in A) print A[i]}' | sort -u"
EOF

cat > "$bash_aliases_file" <<EOF
$alias_content
EOF

chmod 644 "$bash_aliases_file"

log_success "Wrote Setup-Genie aliases to $bash_aliases_file"
log_success "Bash profile setup complete"
