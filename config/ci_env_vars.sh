#!/bin/bash
# config/ci_env_vars.sh

# VM Configuration for CI environment
VM_NAME="ci-test-vm"
VM_RAM="2048"
VM_VCPUS="2"
VM_DISK_SIZE="10G" # Smaller size for CI
VM_OS_VARIANT="debian10"
BRIDGE_INTERFACE=""
VM_BRIDGE="virbr0" # Use default libvirt bridge
VM_DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

# Debian ISO path
VM_ISO_PATH="./dist/debian-12.7.0-amd64-netinst.iso"

# Log file path
LOG_FILE="logs/setup_kvm_$(date +'%Y%m%d_%H%M%S').log"

# CI-specific settings
CI_MODE="true"
SKIP_INTERACTIVE="true"

export VM_NAME VM_RAM VM_VCPUS VM_DISK_SIZE VM_OS_VARIANT VM_BRIDGE VM_DISK_PATH VM_ISO_PATH LOG_FILE CI_MODE SKIP_INTERACTIVE BRIDGE_INTERFACE
