#!/bin/bash
# =============================================================================
# INSTALL DOCKER CE + DOCKER COMPOSE (v2 plugin)
# =============================================================================
# Installs Docker Engine and Docker Compose plugin from the official Docker
# APT repository. Adds the current user to the `docker` group.
#
# Packages installed:
#   docker-ce              — Docker Engine (daemon, containerd, runc)
#   docker-ce-cli          — Docker CLI
#   containerd.io          — Low-level container runtime
#   docker-buildx-plugin   — BuildKit multi-platform build system
#   docker-compose-plugin  — Compose v2 (`docker compose` subcommand)
# =============================================================================
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

if command -v docker &>/dev/null; then
    log_info "Docker already installed ($(docker --version 2>/dev/null)). Skipping."
    exit 0
fi

# =========================
# Docker CE installation
# =========================

log_step "Installing Docker CE prerequisites..."
$apt_get_install ca-certificates curl gnupg

# --- GPG key ---

KEYRING_PATH="/etc/apt/keyrings/docker.gpg"

log_info "Preparing keyrings directory..."
sudo install -m 0755 -d /etc/apt/keyrings

if [ ! -f "$KEYRING_PATH" ]; then
    log_info "Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor \
        | sudo tee "$KEYRING_PATH" > /dev/null
    sudo chmod a+r "$KEYRING_PATH"
else
    log_info "Docker GPG key already present."
fi

# --- APT repository ---

REPO_LIST="/etc/apt/sources.list.d/docker.list"

if [ ! -f "$REPO_LIST" ]; then
    log_info "Adding Docker APT repository..."
    # shellcheck disable=SC1091
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING_PATH}] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee "$REPO_LIST" > /dev/null
    sudo apt-get update -qq
else
    log_info "Docker APT repository already present."
fi

# --- Install packages ---

log_step "Installing Docker CE packages..."
$apt_get_install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# =========================
# Docker daemon
# =========================

log_info "Enabling and starting docker.service..."
sudo systemctl enable docker
sudo systemctl start docker

if sudo systemctl is-active --quiet docker; then
    log_success "docker.service is running."
else
    log_error "docker.service failed to start. Check: sudo journalctl -u docker"
    exit 1
fi

# =========================
# User group membership
# =========================

sudo usermod -aG docker "$USER"
log_warn "Added $USER to the 'docker' group."
log_warn "You must log out and back in (or run: newgrp docker) for this to take effect."

# =========================
# Post-install notes
# =========================

log_success "Docker CE and Docker Compose plugin installed successfully."
log_info "Verify:  docker --version && docker compose version"
log_info "Test:    docker run --rm hello-world"
log_info "Daemon:  sudo systemctl status docker"

## =========================
## First-run workflow
## =========================
##
## 1. Verify engine and compose versions:
##      docker --version
##      docker compose version
##
## 2. Run the smoke-test container (requires group re-login first):
##      newgrp docker            # activate group in current shell, OR
##      logout / login           # full re-login
##      docker run --rm hello-world
##
## 3. Check daemon health:
##      sudo systemctl status docker
##      docker info
##
## 4. Compose quick-start:
##      docker compose up -d     # run a compose.yml in the current directory
##      docker compose logs -f
##      docker compose down
