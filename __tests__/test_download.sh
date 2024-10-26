#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/path.sh"

# Source required files
source "$REPO_ROOT/scripts/message.sh"
source "$REPO_ROOT/scripts/helpers.sh"

# Create temporary test directory
setup() {
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/dist"
    mkdir -p "$TEST_DIR/config"
    
    # Create mock env_vars.sh
    echo 'VM_ISO_PATH=""' > "$TEST_DIR/config/env_vars.sh"
    
    # Save original directory
    ORIG_DIR=$(pwd)
    cd "$TEST_DIR"
}

# Clean up after tests
teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# Mock wget function
mock_wget() {
    # Create a mock wget function that creates a dummy ISO file
    wget() {
        touch "$2"
        return 0
    }
    export -f wget
}

# Test ISO download when file doesn't exist
test_iso_download() {
    message "Testing ISO download when file doesn't exist..." "info"
    
    # Mock wget
    mock_wget
    
    # Run download script with mocked environment
    DEBIAN_VERSION="12.7.0"
    ISO_NAME="debian-${DEBIAN_VERSION}-amd64-netinst.iso"
    ISO_PATH="$TEST_DIR/dist/${ISO_NAME}"
    
    # Source the download script
    source "$REPO_ROOT/download.sh"
    
    # Check if ISO file was created
    if [ -f "$ISO_PATH" ]; then
        message "Test passed: ISO file was created" "success"
    else
        message "Test failed: ISO file was not created" "error"
        return 1
    fi
    
    # Check if env_vars.sh was updated
    if grep -q "VM_ISO_PATH=\"./dist/${ISO_NAME}\"" "$TEST_DIR/config/env_vars.sh"; then
        message "Test passed: VM_ISO_PATH was updated correctly" "success"
    else
        message "Test failed: VM_ISO_PATH was not updated correctly" "error"
        return 1
    fi
}

# Test skip download when ISO exists
test_skip_existing_iso() {
    message "Testing skip download when ISO exists..." "info"
    
    # Create dummy ISO file
    DEBIAN_VERSION="12.7.0"
    ISO_NAME="debian-${DEBIAN_VERSION}-amd64-netinst.iso"
    ISO_PATH="$TEST_DIR/dist/${ISO_NAME}"
    touch "$ISO_PATH"
    
    # Set up file modification time monitoring
    ORIG_MTIME=$(stat -c %Y "$ISO_PATH")
    
    # Source the download script
    source "$REPO_ROOT/download.sh"
    
    # Check if ISO file was not modified
    NEW_MTIME=$(stat -c %Y "$ISO_PATH")
    if [ "$ORIG_MTIME" = "$NEW_MTIME" ]; then
        message "Test passed: Existing ISO file was not modified" "success"
    else
        message "Test failed: Existing ISO file was modified" "error"
        return 1
    fi
}

# Test wget installation check
test_wget_installation() {
    message "Testing wget installation check..." "info"
    
    # Temporarily rename wget to simulate it not being installed
    if which wget > /dev/null; then
        WGET_PATH=$(which wget)
        sudo mv "$WGET_PATH" "${WGET_PATH}.bak"
        
        # Run the check_packages_or_install function
        if check_packages_or_install "wget"; then
            message "Test passed: wget was installed successfully" "success"
        else
            message "Test failed: wget installation failed" "error"
            return 1
        fi
        
        # Restore wget
        sudo mv "${WGET_PATH}.bak" "$WGET_PATH"
    else
        message "Test skipped: wget not found for testing" "warning"
    fi
}

# Main test execution
main() {
    setup
    
    # Run all tests
    test_iso_download
    test_skip_existing_iso
    test_wget_installation
    
    teardown
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi