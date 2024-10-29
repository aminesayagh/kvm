#!/bin/bash

setup_network_bridge() {
    message "Setting up network environment for $VM_BRIDGE..." "info"

    # we'll use the default libvirt network (virbr0)
    if ! virsh net-list --all | grep -q "default"; then
        message "Defining default network..." "info"
        virsh net-define /usr/share/libvirt/networks/default.xml
    fi

    # Start default network if not active
    if ! virsh net-list | grep -q "default"; then
        message "Starting default network..." "info"
        virsh net-start default
        virsh net-autostart default
    fi

    # Verify network is running
    if ip link show "$VM_BRIDGE" >/dev/null 2>&1; then
        message "Default network bridge ($VM_BRIDGE) is ready" "success"
        return 0
    else
        message "Failed to set up network bridge ($VM_BRIDGE)" "error"
        return 1
    fi
}

# Function to verify libvirt network
verify_libvirt_network() {
    message "Verifying libvirt network..." "info"

    # Check if libvirtd is running
    if ! systemctl is-active --quiet libvirtd; then
        message "Starting libvirtd service..." "info"
        systemctl start libvirtd
    fi

    # Wait for service to be fully up
    sleep 5

    # Check network status
    if virsh net-list | grep -q "default.*active"; then
        message "Libvirt default network is active" "success"
        return 0
    else
        message "Libvirt default network is not active" "error"
        return 1
    fi
}
