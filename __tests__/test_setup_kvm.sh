#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../scripts/path.sh"

# Source required files
source "$REPO_ROOT/scripts/message.sh"
source "$REPO_ROOT/scripts/helpers.sh"

# Mock commands and utilities
setup_mocks() {
    # Mock sudo
    sudo() {
        case "$1" in
            "usermod")
                echo "Mock: Adding user to groups"
                return 0
                ;;
            *)
                echo "Mock: sudo $*"
                return 0
                ;;
        esac
    }
    export -f sudo

    # Mock qemu-img
    qemu-img() {
        echo "Mock: Creating disk image $*"
        touch "$4"  # Create mock disk file
        return 0
    }
    export -f qemu-img

    # Mock virt-install
    virt-install() {
        echo "Mock: Installing virtual machine with parameters: $*"
        return 0
    }
    export -f virt-install

    # Mock system commands
    systemctl() {
        echo "Mock: systemctl $*"
        return 0
    }
    export -f systemctl

    # Mock wget command
    wget() {
        echo "Mock: wget $*"
        return 0
    }
    export -f wget

    # Mock tee command
    tee() {
        while read -r line; do
            echo "$line" >> "$1"
            echo "$line"
        done
    }
    export -f tee
}

# Setup test environment
setup() {
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR"/{config,logs,scripts,dist}

    # Create mock config files
    cat > "$TEST_DIR/config/env_vars.sh" << EOF
VM_NAME="test_vm"
VM_RAM="2048"
VM_VCPUS="2"
VM_DISK_SIZE="20G"
VM_OS_VARIANT="debian10"
VM_BRIDGE="br0"
VM_DISK_PATH="$TEST_DIR/images/test_vm.qcow2"
VM_ISO_PATH="$TEST_DIR/dist/debian-test.iso"
LOG_FILE="$TEST_DIR/logs/setup_kvm_test.log"
EOF

    # Create mock ISO file
    touch "$TEST_DIR/dist/debian-test.iso"

    # Save original directory and environment
    ORIG_DIR=$(pwd)
    ORIG_REPO_ROOT="$REPO_ROOT"
    
    # Set test environment
    export REPO_ROOT="$TEST_DIR"
    cd "$TEST_DIR"

    # Setup mocks
    setup_mocks
}

# Cleanup test environment
teardown() {
    cd "$ORIG_DIR"
    export REPO_ROOT="$ORIG_REPO_ROOT"
    rm -rf "$TEST_DIR"
}

# Test log file creation
test_log_creation() {
    message "Testing log file creation..." "info"
    
    # Run setup script in subshell to isolate environment changes and capture output, tee to log file
    (
        source "$REPO_ROOT/setup_kvm.sh" > >(tee -a "$TEST_DIR/logs/setup_kvm_test.log") 2>&1
    ) || true

    sleep 1

    if [ -f "$TEST_DIR/logs/setup_kvm_test.log" ]; then
        if [ -s "$TEST_DIR/logs/setup_kvm_test.log" ]; then
            message "Test passed: Log file was created and contains data" "success"
        else
            message "Test failed: Log file was created but is empty" "error"
            return 1
        fi
    else
        message "Test failed: Log file was not created" "error"
        return 1
    fi
}

# Test disk image creation
test_disk_creation() {
    message "Testing disk image creation..." "info"
    
    source "$REPO_ROOT/setup_kvm.sh" > /dev/null 2>&1 || true
    
    if [ -f "$TEST_DIR/images/test_vm.qcow2" ]; then
        message "Test passed: Disk image was created" "success"
    else
        message "Test failed: Disk image was not created" "error"
        return 1
    fi
}

# Test error handling
test_error_handling() {
    message "Testing error handling..." "info"
    
    # Simulate an error by making VM_DISK_PATH directory read-only
    mkdir -p "$(dirname "$VM_DISK_PATH")"
    chmod 444 "$(dirname "$VM_DISK_PATH")"
    
    if ! source "$REPO_ROOT/setup_kvm.sh" > /dev/null 2>&1; then
        message "Test passed: Script failed as expected when disk creation is not possible" "success"
    else
        message "Test failed: Script should have failed but didn't" "error"
        return 1
    fi
    
    # Restore permissions
    chmod 755 "$(dirname "$VM_DISK_PATH")"
}

# Test user group addition
test_user_groups() {
    message "Testing user group addition..." "info"
    
    source "$REPO_ROOT/setup_kvm.sh" > /dev/null 2>&1 || true
    
    # Check if mock sudo was called with correct parameters
    if grep -q "Mock: Adding user to groups" "$TEST_DIR/logs/setup_kvm_test.log"; then
        message "Test passed: User groups were modified" "success"
    else
        message "Test failed: User groups were not modified" "error"
        return 1
    fi
}

# Test VM installation
test_vm_installation() {
    message "Testing VM installation..." "info"
    
    source "$REPO_ROOT/setup_kvm.sh" > /dev/null 2>&1 || true
    
    # Check if virt-install was called with correct parameters
    if grep -q "Mock: Installing virtual machine with parameters:" "$TEST_DIR/logs/setup_kvm_test.log"; then
        message "Test passed: VM installation was attempted" "success"
    else
        message "Test failed: VM installation was not attempted" "error"
        return 1
    fi
}

# Main test execution
main() {
    setup

    # Run all tests
    test_log_creation
    test_disk_creation
    test_error_handling
    test_user_groups
    test_vm_installation

    teardown
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi