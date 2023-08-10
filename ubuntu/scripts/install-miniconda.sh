#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
apt_get_install="$script_dir/helper_scripts/apt-get-install.sh"
wget_download="$script_dir/helper_scripts/wget-download.sh"

# Install dependencies
$apt_get_install wget

# Download miniconda script
minicondaPath="$script_dir/../setup-files/Miniconda3-latest-Linux-x86_64.sh"
minicondaURL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
$wget_download $minicondaURL $minicondaPath

echo ""
echo "The setup will also you: 'Do you wish the installer to initialize Miniconda3 by running Conda init?' If you type Yes then every time you open the Terminal, Condas base environment will be activated on startup and also this will add the Conda3 folder path in your bash profile. Hence, it is recommended to type 'Yes'"
echo "Whereas those who dont want it, can type “No” and hit the Enter key."
echo ""
echo "In case you have activated the base environment of Condo to start every time with terminal and now you want to deactivate it, then here is the command to follow:"
echo "$ conda config --set auto_activate_base false"
echo ""

bash $minicondaPath
