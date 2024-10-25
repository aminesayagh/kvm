#!/bin/bash

# Set SCRIPT_DIR to the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../scripts/message.sh"

# Test the message function with various types
test_message_function() {
    echo "Testing message function..."

    message "This is an info message."
    message "This is a success message." "success"
    message "This is a warning message." "warning"
    message "This is an error message." "error"
    message "This is a default message." "unknown"

    echo "message function tests completed."
}

# Run tests
test_message_function
