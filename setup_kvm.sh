#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/scripts/path.sh"

# Load environment variables
safe_source "$REPO_ROOT/config/env_vars.sh"

# trap if error occurs on any line
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Load helper functions
safe_source "$REPO_ROOT/scripts/message.sh"
safe_source "$REPO_ROOT/scripts/helpers.sh"

# Run pre-checks
safe_source "$REPO_ROOT/scripts/precheck.sh"

# Run download iso file script
safe_source "$REPO_ROOT/download.sh"

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
