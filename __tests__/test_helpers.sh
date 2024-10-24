#!/bin/bash

# __tests__/test_helpers.sh

source ./scripts/message.sh
source ./scripts/helpers.sh

# Test check_file_exists function
test_check_file_exists() {
    echo "Testing check_file_exists..."

    # Create a temporary file
    touch testfile.tmp

    # Test existing file
    check_file_exists "testfile.tmp" "Test file not found"

    # Test non-existing file
    rm testfile.tmp
    check_file_exists "testfile.tmp" "Test file not found" "continue"

    echo "check_file_exists tests completed."
}

# Test check_directory_exists function
test_check_directory_exists() {
    echo "Testing check_directory_exists..."

    # Create a temporary directory
    mkdir testdir.tmp

    # Test existing directory
    check_directory_exists "testdir.tmp" "Test directory not found"

    # Test non-existing directory
    rmdir testdir.tmp
    check_directory_exists "testdir.tmp" "Test directory not found" "continue"

    echo "check_directory_exists tests completed."
}

# Test give_execution_permission function
test_give_execution_permission() {
    echo "Testing give_execution_permission..."

    # Create a temporary file
    touch testscript.sh

    # Remove execution permission
    chmod -x testscript.sh

    # Grant execution permission
    give_execution_permission "testscript.sh"

    # Verify execution permission
    if [ -x "testscript.sh" ]; then
        message "Execution permission granted successfully." "success"
    else
        message "Failed to grant execution permission." "error"
    fi

    # Clean up
    rm testscript.sh

    echo "give_execution_permission tests completed."
}

# Test check_packages_or_exit function
test_check_packages_or_exit() {
    echo "Testing check_packages_or_exit..."

    # Test with an installed package
    check_packages_or_exit "bash"
}

# Test check_packages_or_install function
test_check_packages_or_install() {
    echo "Testing check_packages_or_install..."

    # Test with an installed package
    check_packages_or_install "bash"
}

# Run tests
test_check_file_exists
test_check_directory_exists
test_give_execution_permission
test_check_packages_or_exit
test_check_packages_or_install
