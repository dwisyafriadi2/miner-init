#!/bin/bash

# Start Miner Script

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process message
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Print the banner
print_banner

# Variables
HOME_DIR=$(eval echo ~$USER)
MINER_BINARY="$HOME_DIR/iniminer-linux-x64"
LOG_FILE="$HOME_DIR/miner.log"

# Check if the binary exists
process_message "Checking Miner Binary"
if [ ! -f "$MINER_BINARY" ]; then
    echo "❌ Miner binary not found at $MINER_BINARY. Please run the setup script first."
    exit 1
fi

# Get user input for wallet address, worker name, and CPU devices
process_message "Collecting User Input"
read -p "Enter your Wallet Address: " WALLET_ADDRESS
read -p "Enter your Worker Name: " WORKER_NAME
read -p "Enter CPU Devices (comma-separated, e.g., 1,2): " CPU_DEVICES

# Convert CPU devices to required format
CPU_FLAGS=""
IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
for DEVICE in "${DEVICES[@]}"; do
    CPU_FLAGS+="--cpu-devices $DEVICE "
done

# Start Miner
process_message "Starting Miner with nohup"
nohup "$MINER_BINARY" \
    --pool "stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672" \
    $CPU_FLAGS > "$LOG_FILE" 2>&1 &

echo "✅ Miner started successfully. Logs are saved in $LOG_FILE"
echo "To monitor logs, run: tail -f $LOG_FILE"
