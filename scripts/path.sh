#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the root directory of the repository
get_repo_root() {
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ] || [ -f "$current_dir/README.md" ]; then
            # Found repository root
            echo "$current_dir"
            return
        else
            # Move up one directory
            current_dir="$(dirname "$current_dir")"
        fi
    done

    # Repository root not found
    echo "Error: Could not determine repository root." >&2
    exit 1
}

REPO_ROOT=$(get_repo_root)