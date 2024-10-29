#!/bin/bash

# shellcheck source=./path.sh
source "$(dirname "${BASH_SOURCE[0]}")/path.sh"

# Load helper functions
safe_source "$REPO_ROOT/scripts/message.sh"
safe_source "$REPO_ROOT/scripts/helpers.sh"
safe_source "$REPO_ROOT/config/env_vars.sh"

# Function to check KVM support
check_kvm_ok() {
  kvm-ok || true
}

# Function to check virtualization support
check_virtualization() {
  # check if cpuinfo has vmx or svm in the output (case insensitive)
  if [ "$(grep -E -c '(vmx|svm)' /proc/cpuinfo)" -eq 0 ]; then
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
check_kvm_ok
check_virtualization
check_root
check_packages_or_install "qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "virt-manager" "lsof" "cpu-checker"

message "All pre-checks passed." "success"
