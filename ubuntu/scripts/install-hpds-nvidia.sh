#!/bin/bash

set -eu -o pipefail

HPDS_STACK_REPO=https://repos.datascience.hp.com/ubuntu

if ! . /etc/os-release; then
    echo "Cannot detect OS. No /etc/os-release found. Exiting..."
    exit 1
fi

if [[ "$ID" != "ubuntu" ]] || [[ ! "$VERSION" =~ ^(20.04|22.04) ]]; then
    printf "Z by HP Data Science Stack Manager is not compatible with $ID $VERSION. It currently only supports Ubuntu 20.04 or 22.04. Exiting...\n"
    exit 1
fi

echo "deb [signed-by=/etc/apt/trusted.gpg.d/hpds.gpg]  $HPDS_STACK_REPO/$UBUNTU_CODENAME/ /" | sudo tee /etc/apt/sources.list.d/repos.datascience.hp.com-ubuntu-$UBUNTU_CODENAME.list
sudo wget $HPDS_STACK_REPO/$UBUNTU_CODENAME/hpds.gpg -O /etc/apt/trusted.gpg.d/hpds.gpg

echo "Re-synchronizing package index files..."
sudo apt-get update
echo ''
echo '@@@@@@@@@(@@@(((((((@@@@@@@@@'
echo '@@@@@@((((@@@((((((((((@@@@@@'
echo '@@@((((((@@@((((((((((((((@@@'
echo '@@((((((@@@((((((((((((((((@@'
echo '@((((((@@@@@@@@(((*@@@@@@@((@'
echo '(((((((@@@((@@@(((@@@((@@@((('
echo '((((((@@@((/@@@((@@@(((@@@((('
echo '(((((@@@(((@@@((@@@(((@@@(((('
echo '((((/@@@((@@@(((@@@((@@@((((('
echo '((((@@@((@@@(((@@@((@@@@((((('
echo '@((@@@(((@@@((@@@@@@@@@(((((@'
echo '@@(((((((((((@@@@((((((((((@@'
echo '@@@((((((((((@@@((((((((((@@@'
echo '@@@@@@((((((@@@((((((((@@@@@@'
echo ''

echo "Installing packages now. Estimated download size: 4 GB"

sudo apt-get -y install hpds-repos && sudo apt-get update

if sudo apt-get -y install hpds-nvidia-cuda; then
    echo "hpds-nvidia-cuda installation complete! Please reboot the system to ensure all changes to take effect."
else
    echo "Failed to install hpds-nvidia-cuda!"
fi

if sudo apt-get -y install nvidia-container-toolkit; then
    echo "Installation complete! Please reboot the system to ensure all changes to take effect."
else
    echo "Failed to install nvidia-container-toolkit!"
fi

