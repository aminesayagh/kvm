#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
setup_network_bridge() {
    local bridge_name="${1:-br0}"
    local physical_interface

    message "Setting up network bridge $bridge_name..." "info"

    # Find primary network interface
    physical_interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [ -z "$physical_interface" ]; then
        message "Could not determine primary network interface" "error"
        return 1
    fi

    # Check if bridge already exists
    if ip link show "$bridge_name" >/dev/null 2>&1; then
        message "Bridge $bridge_name already exists" "info"
        return 0
    fi

    # Backup network configuration
    sudo cp /etc/netplan/* "/etc/netplan/backup_$(date +%Y%m%d_%H%M%S)/"

    # Create netplan configuration
    cat <<EOF | sudo tee "/etc/netplan/02-$bridge_name.yaml"
network:
  version: 2
  renderer: networkd
  ethernets:
    $physical_interface:
      dhcp4: no
  bridges:
    $bridge_name:
      interfaces: [$physical_interface]
      dhcp4: yes
EOF

    # Apply configuration
    sudo netplan try --timeout 60 || {
        message "Failed to apply network configuration" "error"
        return 1
    }
    sudo netplan apply

    # Verify bridge setup
    if ! verify_bridge "$bridge_name"; then
        message "Bridge setup failed" "error"
        return 1
    fi

    message "Bridge $bridge_name setup completed successfully" "success"
    return 0
}

# Function to verify bridge setup
verify_bridge() {
    local bridge_name="$1"
    local timeout=30
    local counter=0

    while [ $counter -lt $timeout ]; do
        if ip link show "$bridge_name" | grep -q "UP"; then
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
    done

    return 1
}
