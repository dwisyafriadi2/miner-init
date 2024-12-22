#!/bin/bash

# Stop Miner Script

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process message
process_message() {
    echo -e "\n\e[41m$1...\e[0m\n" && sleep 1
}

# Print the banner
print_banner

# Check if miner is running
process_message "Checking Miner Process"
PID=$(pgrep -f iniminer-linux-x64)

if [ -z "$PID" ]; then
    echo "❌ No miner process is currently running."
    exit 0
fi

# Kill the process
process_message "Stopping Miner (PID: $PID)"
kill "$PID"

# Verify if it stopped
if [ $? -eq 0 ]; then
    echo "✅ Miner stopped successfully."
else
    echo "❌ Failed to stop the miner. You might need to use sudo."
fi
