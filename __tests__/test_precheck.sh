#!/bin/bash

# __tests__/test_precheck.sh

# Simulate environment variables
export ISO_PATH="./dist/nonexistent.iso"

# Create a mock config/env_vars.sh
echo 'VM_ISO_PATH="./dist/nonexistent.iso"' > config/env_vars.sh

# Source the precheck script
source ./scripts/precheck.sh

# Since precheck.sh runs checks on the actual system, you may want to mock certain functions.
