#!/bin/bash

sudo apt install -y qemu-kvm libvirt-daemon-system virt-manager
sudo usermod -aG libvirt $USER
reboot

## After install be sure to run:
# sudo systemctl start libvirtd
# sudo systemctl enable libvirtd
