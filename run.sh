#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
source "$(dirname "${BASH_SOURCE[0]}")/scripts/path.sh"

# Load helper functions
safe_source "$REPO_ROOT/scripts/message.sh"
safe_source "$REPO_ROOT/scripts/helpers.sh"
safe_source "$REPO_ROOT/config/env_vars.sh"

# Create logs directory
mkdir -p "$REPO_ROOT/logs"

# Set log file for this run
RUN_LOG_FILE="$REPO_ROOT/logs/run_$(date +'%Y%m%d_%H%M%S').log"
exec > >(tee -i "${RUN_LOG_FILE}") 2>&1

# Error handling
set -e
trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    message "Error occurred in run.sh on line $line_number with exit code $exit_code" "error"
    message "Running cleanup..." "warning"
    source "$REPO_ROOT/cleanup" || true
    exit $exit_code
}

# Function to run health checks
run_health_checks() {
    message "Running health checks..." "info"
    local health_check_failed=0
    
    # Get list of health check scripts
    local health_checks=("$REPO_ROOT/healthcheckers"/*.sh)
    
    # Check if directory is empty
    if [ ! -e "${health_checks[0]}" ]; then
        message "No health check scripts found in $REPO_ROOT/healthcheckers/" "warning"
        return 0
    fi
    
    # Run each health check
    for check in "${health_checks[@]}"; do
        if [ -f "$check" ] && [ -x "$check" ]; then
            message "Running health check: $(basename "$check")" "info"
            if ! "$check"; then
                message "Health check failed: $(basename "$check")" "error"
                health_check_failed=1
            fi
        else
            message "Skipping non-executable file: $(basename "$check")" "warning"
        fi
    done
    
    return $health_check_failed
}

# Main execution
main() {
    message "Starting KVM setup process..." "info"
    
    # Run setup script
    message "Running setup_kvm.sh..." "info"
    if ! source "$REPO_ROOT/setup_kvm.sh"; then
        message "Setup failed" "error"
        return 1
    fi
    message "Setup completed successfully" "success"
    
    # Wait for VM to be fully up
    message "Waiting for VM to initialize (30 seconds)..." "info"
    sleep 30
    
    # Run health checks
    if ! run_health_checks; then
        message "Health checks failed" "error"
        return 1
    fi
    message "All health checks passed" "success"
    
    # Ask user if they want to cleanup
    read -p "Do you want to cleanup the installation? (y/N): " cleanup_response
    if [[ "$cleanup_response" =~ ^[Yy]$ ]]; then
        message "Running cleanup..." "info"
        if ! source "$REPO_ROOT/cleanup"; then
            message "Cleanup failed" "error"
            return 1
        fi
        message "Cleanup completed successfully" "success"
    else
        message "Skipping cleanup" "info"
    fi
    
    message "Process completed successfully" "success"
    return 0
}

# Run main function
main
exit $?