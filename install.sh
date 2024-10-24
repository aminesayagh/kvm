#!/bin/bash

# Load environment variables
source config/env_vars.sh
source scripts/message.sh
source scripts/helpers.sh

# Debian version
DEBIAN_VERSION="12.7.0"

# ISO file details
ISO_NAME="debian-${DEBIAN_VERSION}-amd64-netinst.iso"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/${ISO_NAME}"
ISO_PATH="./dist/${ISO_NAME}"

# Update VM_ISO_PATH in config/env_vars.sh
message "Updating VM_ISO_PATH in config/env_vars.sh..." "info"
sed -i.bak "s|^VM_ISO_PATH=.*|VM_ISO_PATH=\"${ISO_PATH}\"|" config/env_vars.sh
message "VM_ISO_PATH updated to '${ISO_PATH}'." "success"

# Create dist directory if it doesn't exist
mkdir -p dist

# Check if wget is installed
check_packages_or_install "wget"

if [ ! -f "${ISO_PATH}" ]; then
    # Download Debian ISO
    message "Downloading Debian ISO..." "info"
    wget -O "${ISO_PATH}" "${ISO_URL}"
    if [ $? -ne 0 ]; then
        message "Failed to download Debian ISO. Exiting..." "error"
        exit 1
    fi
else
    message "Debian ISO already exists. Skipping download." "info"
fi
