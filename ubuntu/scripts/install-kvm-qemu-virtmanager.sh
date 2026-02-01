#!/bin/bash
set -e

# =========================
# Helper scripts
# =========================

script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/../helper-scripts/apt-get-install.sh"
logging_file="$script_dir/../helper-scripts/logging.sh"
write_line="$script_dir/../helper-scripts/write-text-line-in-file.sh"

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

if [ ! -f "$write_line" ]; then
    log_error "write_line_in_file helper not found at: $write_line"
    exit 1
fi

# Core virtualization stack
# - qemu-kvm:       KVM hypervisor
# - libvirt-daemon: VM lifecycle + security boundary
# - virt-manager:   GUI management (control plane)
# - virt-viewer:    Remote Viewer (SPICE desktop client, multi-monitor)
$apt_get_install qemu-kvm libvirt-daemon-system virt-manager virt-viewer

# Allow the current user to manage libvirt VMs without sudo
sudo usermod -aG libvirt $USER

# Append to bash aliases
$write_line ~/.bash_aliases "alias runremoteviewer='remote-viewer spice://localhost:5900'"

log_info "Installation complete."
log_info "You must log out or reboot for libvirt group changes to take effect."

## =========================
## Post-install workflow
## =========================
##
## 1. virt-manager is used ONLY for:
##    - Creating VMs
##    - Configuring hardware (CPU, RAM, disks, GPU heads)
##    - Snapshots / cloning / lifecycle
##
## 2. virt-manager's embedded console is NOT a full desktop viewer.
##    Disable auto-console:
##
##      virt-manager:
##        Edit → Preferences
##        Uncheck: "Automatically open a console when a VM is started"
##
## 3. Configure the VM display (once per VM):
##
##      Display:
##        Type:        SPICE
##        Listen:      Address
##        Address:     Localhost only
##        Port:        5900 (or auto)
##
##      Video:
##        Model:       Virtio
##        Heads:       2 (or more)
##
## 4. Start the VM from virt-manager (no console will open).
##
## 5. Attach with Remote Viewer (primary desktop UX):
##
##      remote-viewer spice://localhost:5900
##
##    Optional fullscreen multi-monitor:
##
##      remote-viewer --full-screen spice://localhost:5900
##
##    In Remote Viewer menu:
##      View → Use All Monitors
##
## 6. GNOME inside the VM will see multiple displays and remember layout.
##
## Notes:
## - Do NOT run virt-manager console and remote-viewer at the same time.
## - Closing virt-manager's console fully detaches it (no wasted resources).
## - This setup is snapshot-safe, clone-safe, and golden-image friendly.
