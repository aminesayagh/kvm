#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export SCRIPT_DIR

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

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

export REPO_ROOT

safe_source() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        # shellcheck disable=SC1090
        source "$script_path" > /dev/null 2>&1 || true
    else
        if command -v message > /dev/null 2>&1; then
            message "Error: Script not found: $script_path" "error"
        else
            echo "Error: Script not found: $script_path" >&2
        fi
        exit 1
    fi
}
