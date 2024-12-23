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
PIDS=$(pgrep -f iniminer-linux-x64)

if [ -z "$PIDS" ]; then
    echo "❌ No miner process is currently running."
    exit 0
fi

# Kill each process
process_message "Stopping Miner Processes"
for PID in $PIDS; do
    echo "Stopping PID: $PID"
    kill "$PID"
    if [ $? -eq 0 ]; then
        echo "✅ Process $PID stopped successfully."
    else
        echo "❌ Failed to stop process $PID. You might need to use sudo."
    fi
done

# Verify if all processes are stopped
REMAINING_PIDS=$(pgrep -f iniminer-linux-x64)
if [ -z "$REMAINING_PIDS" ]; then
    echo "✅ All miner processes have been stopped."
else
    echo "❌ Some miner processes are still running: $REMAINING_PIDS"
    echo "Try running the script with sudo:"
    echo "sudo ./stop.sh"
fi
