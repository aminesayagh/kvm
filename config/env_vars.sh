# config/env_vars.sh

# VM Configuration
VM_NAME="myvm"
VM_RAM="2048"
VM_VCPUS="2"
VM_DISK_SIZE="20G"
VM_OS_VARIANT="debian10"
VM_BRIDGE="br0"
VM_DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

# Log file path
LOG_FILE="logs/setup_kvm_$(date +'%Y%m%d_%H%M%S').log"
