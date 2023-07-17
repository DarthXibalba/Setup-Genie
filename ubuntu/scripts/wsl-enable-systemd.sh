#!/bin/bash

# Check if /etc/wsl.conf exists
if [ ! -f "/etc/wsl.conf" ]; then
    echo "/etc/wsl.conf does not exist. Creating the file..."
    sudo touch /etc/wsl.conf
fi

# Check if the lines already exist in /etc/wsl.conf
if ! grep -q "\[boot\]" /etc/wsl.conf || ! grep -q "systemd=true" /etc/wsl.conf; then
    echo "Adding the lines to /etc/wsl.conf..."
    echo "[boot]" | sudo tee -a /etc/wsl.conf >/dev/null
    echo "systemd=true" | sudo tee -a /etc/wsl.conf >/dev/null
    echo "Lines added successfully!"
else
    echo "The lines already exist in /etc/wsl.conf. No changes needed."
fi
