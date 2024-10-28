#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/path.sh"

# Function to check if a file exists
check_file_exists() {
  local file_path="$1"
  local error_message="${2:-File not found: $file_path}" # Default error message if not provided
  local continue_on_failure="$3"

  if [ ! -f "$file_path" ]; then
    message "$error_message" "error"
    if [ "$continue_on_failure" != "continue" ]; then
      exit 1
    fi
  else
    message "File found: $file_path" "success"
  fi
}

# Function to check if a directory exists
check_directory_exists() {
  local dir_path="$1"
  local error_message="${2:-Directory not found: $dir_path}"
  local continue_on_failure="$3"

  if [ ! -d "$dir_path" ]; then
    message "$error_message" "error"
    if [ "$continue_on_failure" != "continue" ]; then
      exit 1
    fi
  else
    message "Directory found: $dir_path" "success"
  fi
}

# Function to give execution permission to a file
give_execution_permission() {
    local file_path="$1"
    local error_message="${2:-File not found: $file_path}"
    local continue_on_failure="$3"

    if [ ! -f "$file_path" ]; then
        message "$error_message" "error"
        if [ "$continue_on_failure" != "continue" ]; then
          exit 1
        fi
    else
        message "Giving execution permission to $file_path..." "info"
        chmod +x "$file_path"
        message "Execution permission granted to $file_path" "success"
    fi
}

check_packages_or_exit() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            message "Package $pkg is installed" "success"
        else
            message "Package $pkg is not installed" "error"
            exit 1
        fi
    done
}

check_packages_or_install() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            message "Package $pkg is installed" "success"
        else
            message "Package $pkg is not installed. Installing..." "info"
            sudo apt-get install -y "$pkg"
            if [ ! $? ]; then
                message "Failed to install package $pkg" "error"
                exit 1
            fi
        fi
    done
}