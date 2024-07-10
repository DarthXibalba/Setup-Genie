#!/bin/bash
set -eu -o pipefail

# Define valid flags
declare -a valid_flags=("wsl-ubuntu" "ubuntu")

# Function to display script usage
display_usage() {
    local valid_flags_string="${valid_flags[*]}"
    local usage_message="Usage: $0 [${valid_flags_string// / | }]"
    echo "$usage_message"
}

# Check if the script is run without any arguments
if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

# Check if more than one flag is provided
if [ $# -gt 1 ]; then
    echo "Error! Only one flag can be provided."
    display_usage
    exit 1
fi

# Get the flag from the command-line argument
flag="$1"

# Check if the flag is a valid flag
if [[ " ${valid_flags[*]} " =~ " ${flag} " ]]; then
    # The following snippet is derived from the following HPDS installation script: https://github.azc.ext.hp.com/WorkstationsAI/ds-stack-packages/blob/develop/user_scripts/install_hpds_stack.sh
    if [ "ubuntu" == "${flag}" ]; then
        echo "Installing packages for Ubuntu..."
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

        echo "Installing packages now. Estimated download size: 4 GB"

        sudo apt-get -y install hpds-repos && sudo apt-get update

        if sudo apt-get -y install hpds-nvidia-cuda; then
            echo "hpds-nvidia-cuda installation complete! Please reboot the system to ensure all changes to take effect."
        else
            echo "Failed to install hpds-nvidia-cuda!"
        fi

        if sudo apt-get install -y nvidia-container-toolkit; then
            echo "Installation complete! Please reboot the system to ensure all changes to take effect."
        else
            echo "Failed to install nvidia-container-toolkit!"
        fi

    # The following snippet is derived from the following HPDS installation script: https://github.azc.ext.hp.com/phoenix/installer/blob/4f89c87fb3c63fc89f938f1bad36442487b09449/windows/wsl/install.sh#L19
    # And the following debian package control file: https://github.azc.ext.hp.com/phoenix/installer/blob/dd87c976282617e1a61e6ff8a051274f45e1c2e1/windows/wsl/control_template
    elif [ "wsl-ubuntu" == "${flag}" ]; then
        echo "Installing packages for WSL Ubuntu..."

        # Add package repositories
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        CONTAINER_TK_KEYRING=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        CONTAINER_TK_APT_SOURCE=/etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo rm -f $CONTAINER_TK_KEYRING
        sudo rm -f $CONTAINER_TK_APT_SOURCE
        wget -q -O - https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o $CONTAINER_TK_KEYRING
        wget -q -O - https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee $CONTAINER_TK_APT_SOURCE
        sudo apt-get update

        # Install nvidia-container-toolkit from configured sources
        if sudo apt-get install -y nvidia-container-toolkit; then
            echo "Installation complete! Please reboot WSL to ensure all changes take effect."
        else
            echo "Failed to install nvidia-container-toolkit!"
        fi
    fi
else
    # Invalid flag provided
    display_usage
    exit 1
fi
