#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/scripts/path.sh"

# Load environment variables
safe_source "$REPO_ROOT/config/env_vars.sh"

# trap if error occurs on any line
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Load helper functions
safe_source "$REPO_ROOT/scripts/message.sh"
safe_source "$REPO_ROOT/scripts/helpers.sh"

requirements_check() {
    # Enable and start libvirtd service
    # This is required for virt-install to work
    message "Enabling and starting libvirtd service..." "info"
    sudo systemctl enable --now libvirtd

    # Run pre-checks
    safe_source "$REPO_ROOT/scripts/precheck.sh"

    # Run download iso file script
    safe_source "$REPO_ROOT/download.sh"
}

user_setup() {
    local kvm_user="${KVM_USER:-kvmadmin}"
    local kvm_group="${KVM_GROUP:-kvmadmin}"

    message "Setting up user ${kvm_user} with group ${kvm_group}..." "info"

    # Create group if it doesn't exist
    if ! getent group "${kvm_group}" >/dev/null 2>&1; then
        sudo groupadd "${kvm_group}"
        message "Group ${kvm_group} created." "success"
    fi

    if ! id -u "${kvm_user}" >/dev/null 2>&1; then
        sudo useradd -m -s /bin/bash -G "${kvm_group}" "${kvm_user}"

        local cred_file="${REPO_ROOT}/config/.kvm_credentials"
        local password
        # if cred_file does not exist, create it
        if [[ ! -f "${cred_file}" ]]; then
            password=$(openssl rand -base64 12)
            # The chpasswd command administers users' passwords. The root user can supply or change users' passwords specified through standard input. Each line of input must be of the following format.
            echo "$kvm_user:$password" | sudo chpasswd

            echo "KVM_USER=$kvm_user" >"$cred_file"
            echo "KVM_PASSWORD=$password" >>"$cred_file"
            chmod 600 "$cred_file" # Make the file readable only by root

            message "User ${kvm_user} created with password ${password}." "success"
        else
            message "User ${kvm_user} already exists." "warning"

            # Read the credentials from the file
            if [[ -f "$cred_file" ]]; then
                source "$cred_file"
            else
                message "Credentials file ${cred_file} not found." "error"
                exit 1
            fi
        fi

        # Add user to required groups
        # For every group in the list "libvirt kvm $kvm_group", add the user to the group if they are not already in it
        for group in libvirt kvm "$kvm_group"; do
            if ! groups "$kvm_user" | grep -q "\b$group\b"; then
                # -aG option appends the user to the supplementary group list for the user
                sudo usermod -aG "$group" "$kvm_user"
                message "Added $kvm_user to group $group" "success"
            fi
        done

        # Set up sudo access for KVM management
        local sudoers_file="/etc/sudoers.d/${kvm_user}"

        local sudoers_file="/etc/sudoers.d/kvm-management"
        if [ ! -f "$sudoers_file" ]; then
            echo "$kvm_user ALL=(ALL) NOPASSWD: /usr/bin/virsh, /usr/bin/qemu-img, /usr/bin/virt-install" | sudo tee "$sudoers_file"
            sudo chmod 440 "$sudoers_file"
            message "Set up sudo access for KVM management" "success"
        fi

        # Apply group membership immediately using newgrp
        # This is done in a subshell to avoid affecting the parent shell
        if [ "$USER" = "$kvm_user" ]; then
            (
                # Refresh group membership without logout
                for group in libvirt kvm "$kvm_group"; do
                    sudo -u "$kvm_user" newgrp "$group"
                done
            )
            message "Group memberships applied successfully" "success"
        fi

        # Update environment variables
        echo "KVM_USER=$kvm_user" >>"$REPO_ROOT/config/env_vars.sh"
        echo "KVM_GROUP=$kvm_group" >>"$REPO_ROOT/config/env_vars.sh"

        message "User setup completed successfully" "success"

        # Return the KVM user for use in other functions
        echo "$kvm_user"
    fi
}

disk_setup() {
    local kvm_user="$1"

    message "Creating disk image for ${VM_DISK_PATH}..." "info"

    # Create the directory for the disk image
    sudo mkdir -p "$(dirname "${VM_DISK_PATH}")"
    sudo chown -R "${kvm_user}:${kvm_group}" "$(dirname "${VM_DISK_PATH}")"

    # Create the disk image as the kvm_user
    sudo -u "${kvm_user}" qemu-img create -f qcow2 "${VM_DISK_PATH}" "${VM_DISK_SIZE}"

    # Set permissions for the disk image
    sudo chmod 660 "${VM_DISK_PATH}"
}

vm_setup() {
    message "Starting virtual machine installation..." "info"
    virt-install \
        --name "${VM_NAME}" \
        --ram "${VM_RAM}" \
        --vcpus "${VM_VCPUS}" \
        --disk path="${VM_DISK_PATH}" \
        --os-variant "${VM_OS_VARIANT}" \
        --network bridge="${VM_BRIDGE}" \
        --graphics none \
        --console pty,target_type=serial \
        --location "${VM_ISO_PATH}" \
        --extra-args 'console=ttyS0,115200n8 serial'
}

main() {
    local kvm_user

    requirements_check
    kvm_user=$(user_setup)
    disk_setup "$kvm_user"
    vm_setup "$kvm_user"

    message "Setup completed successfully." "success"
}

main
