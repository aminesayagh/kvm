#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/path.sh"

# Load helper functions
source "$SCRIPT_DIR/message.sh"
source "$SCRIPT_DIR/helpers.sh"
source "$SCRIPT_DIR/../config/env_vars.sh"

# Function to check virtualization support
check_virtualization() {
  if [ "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" -eq 0 ]; then
    message "Error: CPU does not support virtualization." "error"
    exit 1
  else
    message "Virtualization support detected." "success"
  fi
}

# Function to check if running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    message "Error: Please run as root or use sudo." "error"
    exit 1
  else
    message "Running with sufficient privileges." "success"
  fi
}

# Run checks
check_virtualization
check_root
check_packages_or_install "qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "virt-manager" "lsof"

check_file_exists "${ISO_PATH}" "Error: ISO file not found at ${ISO_PATH}"

message "All pre-checks passed." "success"
