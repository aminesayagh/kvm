#!/bin/bash

# Load environment variables
source config/env_vars.sh

# Create log file
set -e

trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

mkdir -p logs

exec > >(tee -i "${LOG_FILE}") 2>&1

# Load helper functions
source scripts/message.sh
source scripts/helpers.sh

# Run pre-checks
source scripts/precheck.sh

# Run install script
source install.sh

message "Adding $USER to libvirt and kvm groups..." "info"
sudo usermod -aG libvirt,kvm "$USER"

message "Added $USER to libvirt and kvm groups. Please log out and log back in for changes to take effect." "warning"

message "Creating disk image for ${VM_DISK_PATH}..." "info"
qemu-img create -f qcow2 "${VM_DISK_PATH}" "${VM_DISK_SIZE}"

message "Starting virtual machine installation..." "info"
virt-install \
    --name "${VM_NAME}" \
    --ram "${VM_RAM}" \
    --vcpus "${VM_VCPUS}" \
    --disk path="${VM_DISK_PATH}" \
    --os-variant "${VM_OS_VARIANT}" \
    --network bridge="${VM_BRIDGE}" \
    --graphics none \
    --console pty,target_type=serial \
    --location "${VM_ISO_PATH}" \
    --extra-args 'console=ttyS0,115200n8 serial'

message "Virtual machine installation completed." "success"
