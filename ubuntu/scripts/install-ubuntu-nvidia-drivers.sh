#!/bin/bash

driver_branch="535"
linux_kernel=$(uname -r)

# Install the pre-compiled NVIDIA kernel modules
sudo apt install -y linux-modules-nvidia-$driver_branch-$linux_kernel
# Install the user-space drivers and the driver libraries
sudo apt install -y nvidia-driver-$driver_branch

echo "Installation complete! Please reboot the system to ensure all changes to take effect."
