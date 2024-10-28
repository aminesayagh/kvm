#!/bin/bash
# config/env_vars.sh

# VM Configuration
VM_NAME="myvm"
VM_RAM="2048"
VM_VCPUS="2"
VM_DISK_SIZE="20G"
VM_OS_VARIANT="debian10"
# VM Bridge is the name of the bridge in the host machine
# bridge is a network device in the host machine
VM_BRIDGE="br0"
VM_DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

# Debian ISO path
VM_ISO_PATH="./dist/debian-12.7.0-amd64-netinst.iso"

# Log file path
LOG_FILE="logs/setup_kvm_$(date +'%Y%m%d_%H%M%S').log"

export VM_NAME VM_RAM VM_VCPUS VM_DISK_SIZE VM_OS_VARIANT VM_BRIDGE VM_DISK_PATH VM_ISO_PATH LOG_FILE
