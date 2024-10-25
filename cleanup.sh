#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config/env_vars.sh"
source "$SCRIPT_DIR/scripts/message.sh"

remove_vm() {
    message "Shutting down and undefining VM '${VM_NAME}'..." "info"
    
    # Check if VM exists
    if virsh dominfo "${VM_NAME}" >/dev/null 2>&1; then
        # Shutdown VM if it's running
        if [ "$(virsh domstate "${VM_NAME}")" = "running" ]; then
            virsh shutdown "${VM_NAME}"
            sleep 5  # Wait for the VM to shut down gracefully
            # Force shutdown if still running
            if [ "$(virsh domstate "${VM_NAME}")" = "running" ]; then
                virsh destroy "${VM_NAME}"
            fi
        fi
        
        # Undefine VM
        virsh undefine "${VM_NAME}" --remove-all-storage
        message "VM '${VM_NAME}' has been undefined and its storage removed." "success"
    else
        message "VM '${VM_NAME}' does not exist. Skipping removal." "warning"
    fi
}

# Function to remove disk image
remove_dist_image() {
    if [ -f "${VM_DISK_PATH}" ]; then
        rm -f "${VM_DISK_PATH}"
        message "Disk image '${VM_DISK_PATH}' has been removed." "success"
    else
        message "Disk image '${VM_DISK_PATH}' does not exist. Skipping removal." "warning"
    fi
}

# Function to remove logs
remove_logs() {
    if [ -d "logs" ]; then
        rm -rf logs/*
        message "All logs have been removed." "success"
    else
        message "Logs directory does not exist. Skipping log cleanup." "warning"
    fi
}

# Function to remove group memberships
remove_group_memberships() {
    # Remove user from groups
    message "Removing $USER from 'libvirt' and 'kvm' groups..." "info"
    deluser "$USER" libvirt
    deluser "$USER" kvm
    message "User $USER has been removed from 'libvirt' and 'kvm' groups." "success"
    message "Please log out and log back in for changes to take effect." "warning"
}

# Execute cleanup functions
remove_vm
remove_disk_image
remove_logs
remove_group_memberships

message "Cleanup completed." "success"