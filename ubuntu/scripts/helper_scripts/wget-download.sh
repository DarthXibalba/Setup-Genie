#!/bin/bash

if [ $# -ne 2 ]; then
    echo "This script downloads (via wget) the first argument (argURL) to the second argument (argPath)"
    echo "Usage $0 <argURL> <argPath>"
    exit 1
fi

argURL="$1"
argPath="$2"

# Check if the file already exists at argPath, download if it doesn't exist
if [ ! -f "$argPath"  ]; then
    echo "downloading "$argURL" -> "$argPath
    sudo wget $argURL -O $argPath
fi
