#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Simulate environment variables
export ISO_PATH="./dist/mock.iso"

mkdir -p "$SCRIPT_DIR/../dist"
touch "$SCRIPT_DIR/../dist/mock.iso"

# Create a mock config/env_vars.sh
echo 'VM_ISO_PATH="./dist/mock.iso"' > "$SCRIPT_DIR/../config/env_vars.sh"

# Source the precheck script
source "$SCRIPT_DIR/../scripts/precheck.sh"

# Since precheck.sh runs checks on the actual system, you may want to mock certain functions.
