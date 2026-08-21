#!/bin/bash
# =============================================================================
# INSTALL DOCKER CE + DOCKER COMPOSE (v2 plugin)
# =============================================================================
# Installs Docker Engine and the Docker Compose plugin from Docker's official
# Fedora repository. Enables the Docker daemon and gives the invoking user
# permission to run Docker without sudo.
#
# Packages installed:
#   docker-ce              - Docker Engine
#   docker-ce-cli          - Docker CLI
#   containerd.io          - Container runtime
#   docker-buildx-plugin   - BuildKit build plugin
#   docker-compose-plugin  - Compose v2 (`docker compose`)
# =============================================================================
set -euo pipefail

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
dnf_install="$script_dir/../helper-scripts/dnf-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"

if [ ! -f "$logging_file" ]; then
    echo "ERROR: logging helper not found at: $logging_file"
    exit 1
fi

# shellcheck source=/dev/null
source "$logging_file"

if [ ! -x "$dnf_install" ]; then
    log_error "DNF install helper is missing or not executable: $dnf_install"
    exit 1
fi

# =========================
# Preconditions
# =========================

if [ ! -r /etc/os-release ]; then
    log_error "Cannot identify the operating system: /etc/os-release is missing."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

if [ "${ID:-}" != "fedora" ]; then
    log_error "This installer supports Fedora only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install Docker."
    exit 1
fi

target_user="${SUDO_USER:-${USER:-}}"
if [ -z "$target_user" ]; then
    log_error "Could not determine which user should receive Docker access."
    exit 1
fi

# =========================
# Remove conflicting packages
# =========================

conflicting_packages=(
    docker
    docker-client
    docker-client-latest
    docker-common
    docker-latest
    docker-latest-logrotate
    docker-logrotate
    docker-selinux
    docker-engine-selinux
    docker-engine
    podman-docker
)
installed_conflicts=()

for package in "${conflicting_packages[@]}"; do
    if rpm -q "$package" &>/dev/null; then
        installed_conflicts+=("$package")
    fi
done

if [ ${#installed_conflicts[@]} -gt 0 ]; then
    log_warn "Removing packages that conflict with Docker CE: ${installed_conflicts[*]}"
    sudo dnf remove -y "${installed_conflicts[@]}"
else
    log_info "No conflicting Docker packages found."
fi

# =========================
# Docker repository
# =========================

repo_file="/etc/yum.repos.d/docker-ce.repo"
repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"

"$dnf_install" dnf-plugins-core

if [ ! -f "$repo_file" ]; then
    log_step "Adding Docker's official Fedora repository..."

    # Fedora's current DNF 5 syntax, with a fallback for older DNF releases.
    if dnf config-manager addrepo --help &>/dev/null; then
        sudo dnf config-manager addrepo --from-repofile "$repo_url"
    else
        sudo dnf config-manager --add-repo "$repo_url"
    fi

    log_success "Docker repository added."
else
    log_info "Docker repository already configured."
fi

# =========================
# Docker CE installation
# =========================

log_step "Installing Docker CE and Docker Compose..."
"$dnf_install" \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# =========================
# Docker daemon
# =========================

log_step "Enabling and starting docker.service..."
sudo systemctl enable --now docker

if sudo systemctl is-active --quiet docker; then
    log_success "docker.service is running."
else
    log_error "docker.service failed to start. Check: sudo journalctl -u docker"
    exit 1
fi

# =========================
# User group membership
# =========================

if [ "$target_user" = "root" ]; then
    log_warn "Installer was invoked as root; no non-root user was added to the docker group."
elif id -nG "$target_user" | grep -qw docker; then
    log_info "$target_user is already a member of the docker group."
else
    sudo usermod -aG docker "$target_user"
    log_warn "Added $target_user to the docker group."
    log_warn "Log out and back in, or run 'newgrp docker', before using Docker without sudo."
fi

# =========================
# Verification
# =========================

if ! docker compose version &>/dev/null; then
    log_error "Docker Compose was installed but its version check failed."
    exit 1
fi

# =========================
# Post-install notes
# =========================

log_success "Docker CE and Docker Compose installed successfully."
log_info "Docker:  $(docker --version)"
log_info "Compose: $(docker compose version)"
log_info "Test:    docker run --rm hello-world"
log_info "Daemon:  sudo systemctl status docker"

## =========================
## First-run workflow
## =========================
##
## 1. Activate docker-group membership:
##      newgrp docker            # current shell, or log out and back in
##
## 2. Verify the installation:
##      docker --version
##      docker compose version
##      docker run --rm hello-world
##
## 3. Use Compose in a directory containing compose.yml:
##      docker compose up -d
##      docker compose logs -f
##      docker compose down
