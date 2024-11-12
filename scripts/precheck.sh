#!/bin/bash

# shellcheck source=./path.sh
source "$(dirname "${BASH_SOURCE[0]}")/path.sh"

# Load helper functions
safe_source "$REPO_ROOT/scripts/message.sh"
safe_source "$REPO_ROOT/scripts/helpers.sh"
safe_source "$REPO_ROOT/scripts/network-bridge.sh"
safe_source "$REPO_ROOT/config/ci_env_vars.sh"

# Function to check KVM support
check_kvm_ok() {
  message "Checking KVM support..." "info"
  kvm-ok || true
  message "KVM support checked." "success"
}

# Function to check virtualization support
check_virtualization() {
  message "Checking virtualization support..." "info"
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
  message "Checking if running as root..." "info"
  if [ "$EUID" -ne 0 ]; then
    message "Error: Please run as root or use sudo." "error"
    exit 1
  else
    message "Running with sufficient privileges." "success"
  fi
}

# Function to check network configuration
check_network() {
  message "Checking network configuration..." "info"

  # Check if bridge exists and is up
  if ! ip link show "$VM_BRIDGE" >/dev/null 2>&1; then
    message "Network bridge not found. Setting up bridge..." "info"
    setup_network_bridge "$VM_BRIDGE" || exit 1
  fi

  # Check bridge status
  if ! ip link show "$VM_BRIDGE" | grep -q "UP"; then
    message "Network bridge '$VM_BRIDGE' is not up" "error"
    return 1
  fi

  # Check if libvirt networking is running
  if ! systemctl is-active --quiet libvirtd; then
    message "libvirtd service is not running" "error"
    return 1
  fi

  message "Network configuration is valid" "success"
  return 0
}

# Function to check disk space
check_disk_space() {
  message "Checking available disk space..." "info"

  # Extract numeric value from VM_DISK_SIZE
  local required_size
  required_size=$(echo "$VM_DISK_SIZE" | sed 's/[^0-9]//g' | awk '{print $1}') # Extract first number only
  local target_dir
  target_dir=$(dirname "$VM_DISK_PATH")

  # Convert to KB for comparison (assuming VM_DISK_SIZE is in GB)
  local required_kb=$((required_size * 1024 * 1024))
  local available_kb
  available_kb=$(df -k "$target_dir" | awk 'NR==2 {print $4}')

  # Add 20% buffer for overhead
  local required_with_buffer=$((required_kb * 120 / 100))

  if [ "$available_kb" -lt "$required_with_buffer" ]; then
    message "Insufficient disk space. Required: $((required_with_buffer / 1024 / 1024))GB (including buffer), Available: $((available_kb / 1024 / 1024))GB" "error"
    return 1
  fi

  message "Sufficient disk space available" "success"
  return 0
}

precheck() {
  message "Running pre-checks..." "info"

  local failed=0

  check_packages_or_install "kvm-ok" "qemu-kvm" "libvirt-daemon-system" "virsh" "libvirt-clients" "bridge-utils" "virt-manager" "lsof" "cpu-checker" || failed=1
  check_kvm_ok || failed=1
  check_virtualization || failed=1
  check_network || failed=1
  check_disk_space || failed=1
  check_root || failed=1

  if [ $failed -eq 1 ]; then
    message "Pre-checks failed." "error"
    exit 1
  else
    message "All pre-checks passed." "success"
  fi
}

echo "Running pre-checks..."
# Run checks
precheck
