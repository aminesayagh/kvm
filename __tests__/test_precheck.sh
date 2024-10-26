#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/path.sh"

# Simulate environment variables
export ISO_PATH="./dist/mock.iso"

mkdir -p "$REPO_ROOT/dist"
touch "$REPO_ROOT/dist/mock.iso"

# Create a mock config/env_vars.sh
echo 'VM_ISO_PATH="./dist/mock.iso"' > "$REPO_ROOT/config/env_vars.sh"

rm -rf "$REPO_ROOT/dist/mock.iso"
export VM_ISO_PATH=""

# Source the precheck script
source "$REPO_ROOT/scripts/precheck.sh"
