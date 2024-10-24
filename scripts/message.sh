#!/bin/bash

# Function to format and display messages
# Parameters:
#   $1: The message to show (mandatory)
#   $2: The flag for the type of message ('error', 'warning', 'success', 'info') (optional, defaults to 'info')
message() {
    local message="$1"
    local type="${2:-info}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # ANSI color codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    # Select color based on message type
    case "$type" in
        "error") color=$RED ;;
        "success") color=$GREEN ;;
        "warning") color=$YELLOW ;;
        *) color=$BLUE ;;
    esac

    # Print colored message to terminal
    echo -e "${color}[${type^^}] [$timestamp] $message${NC}"
}
