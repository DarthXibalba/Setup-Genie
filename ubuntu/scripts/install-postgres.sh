#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

if [ ! -f "$apt_get_install" ]; then
    log_error "apt-get helper not found at: $apt_get_install"
    exit 1
fi

# =========================
# Idempotency guard
# =========================

if command -v psql &>/dev/null; then
    log_info "PostgreSQL already installed ($(psql --version)). Skipping."
    exit 0
fi

# =========================
# PostgreSQL installation
# =========================

log_step "Installing PostgreSQL..."
$apt_get_install postgresql postgresql-client

# =========================
# Service check
# =========================

log_info "Enabling postgresql.service..."
sudo systemctl daemon-reload
sudo systemctl enable postgresql

if sudo systemctl is-active --quiet postgresql; then
    log_success "postgresql.service is running."
else
    log_error "postgresql.service failed to start. Check: sudo journalctl -u postgresql"
    exit 1
fi

# =========================
# Post-install notes
# =========================

log_success "PostgreSQL installed successfully."
log_info "Verify:   psql --version"
log_info "Status:   sudo systemctl status postgresql"
log_info "Connect:  sudo -u postgres psql"

## =========================
## First-run workflow
## =========================
##
##   1. Connect as superuser:
##        sudo -u postgres psql
##
##   2. Set a password for the postgres role:
##        ALTER USER postgres PASSWORD 'yourpassword';
##
##   3. Create a database and app user:
##        CREATE USER appuser WITH PASSWORD 'secret';
##        CREATE DATABASE appdb OWNER appuser;
##
##   4. Allow local password auth (optional — edit pg_hba.conf):
##        sudo nano /etc/postgresql/17/main/pg_hba.conf
##        # change "peer" → "md5" for local connections, then:
##        sudo systemctl restart postgresql
##
##   5. Test remote connectivity (if needed):
##        # Edit postgresql.conf: listen_addresses = '*'
##        # Open firewall: sudo ufw allow 5432/tcp
