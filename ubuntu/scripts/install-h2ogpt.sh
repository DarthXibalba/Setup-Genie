#!/bin/bash
# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"

# Install dependencies
$script_dir"/install-miniconda.sh"


# Clone the H2O GPT repo
basedir = "$HOME"
echo "git clone https://github.com/h2oai/h2ogpt.git $HOME"
git clone https://github.com/h2oai/h2ogpt.git $HOME

echo "cd h2ogpt"
cd h2ogpt

# Create new conda environment
echo "conda create --name=h2ogpt python=3.10"
conda create --name=h2ogpt python=3.10
