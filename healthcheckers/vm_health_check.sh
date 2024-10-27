#!/bin/bash


# Set SCRIPT_DIR to the directory where this script resides
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/path.sh"

# Load helper functions
source "$REPO_ROOT/scripts/message.sh"
source "$REPO_ROOT/scripts/helpers.sh"
source "$REPO_ROOT/config/env_vars.sh"

# Check if VM exists
check_vm_exists() {
    if virsh dominfo "${VM_NAME}" >/dev/null 2>&1; then
        message "VM ${VM_NAME} exists" "success"
        return 0
    else
        message "VM ${VM_NAME} does not exist" "error"
        return 1
    fi
}

# Check if VM is running
check_vm_running() {
    if [ "$(virsh domstate "${VM_NAME}" 2>/dev/null)" = "running" ]; then
        message "VM ${VM_NAME} is running" "success"
        return 0
    else
        message "VM ${VM_NAME} is not running" "error"
        return 1
    fi
}

# Check if disk image exists
check_disk_exists() {
    if [ -f "${VM_DISK_PATH}" ]; then
        message "Disk image exists at ${VM_DISK_PATH}" "success"
        return 0
    else
        message "Disk image not found at ${VM_DISK_PATH}" "error"
        return 1
    fi
}

# Check user groups
check_user_groups() {
    if groups "$USER" | grep -q "\b\(libvirt\|kvm\)\b"; then
        message "User $USER is in required groups" "success"
        return 0
    else
        message "User $USER is not in required groups" "error"
        return 1
    fi
}

# Main health check execution
main() {
    local failed=0
    
    check_vm_exists || failed=1
    check_vm_running || failed=1
    check_disk_exists || failed=1
    check_user_groups || failed=1
    
    if [ $failed -eq 0 ]; then
        message "All checks passed" "success"
        return 0
    else
        message "Some checks failed" "error"
        return 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
