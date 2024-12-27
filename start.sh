#!/bin/bash

# ---------------------------
# Miner Start Script with Auto-Restart and nohup
# ---------------------------

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
LOG_FILE="$HOME_DIR/miner-init/miner.log"
CONFIG_FILE="$HOME_DIR/miner-init/miner_config.conf"

# Check if the binary exists
process_message "Checking Miner Binary"
if [ ! -f "$MINER_BINARY" ]; then
    echo "❌ Miner binary not found at $MINER_BINARY. Please run the setup script first."
    exit 1
fi

# Function to save user inputs to config
save_config() {
    echo "WALLET_ADDRESS=$WALLET_ADDRESS" > "$CONFIG_FILE"
    echo "WORKER_NAME=$WORKER_NAME" >> "$CONFIG_FILE"
    echo "CPU_DEVICES=$CPU_DEVICES" >> "$CONFIG_FILE"
}

# Function to load config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "✅ Configuration loaded from $CONFIG_FILE"
    else
        process_message "Collecting User Input"
        while [[ -z "$WALLET_ADDRESS" ]]; do
            read -p "Enter your Wallet Address: " WALLET_ADDRESS
        done

        while [[ -z "$WORKER_NAME" ]]; do
            read -p "Enter your Worker Name: " WORKER_NAME
        done

        while [[ -z "$CPU_DEVICES" ]]; do
            read -p "Enter CPU Devices (comma-separated, e.g., 0,1,2): " CPU_DEVICES
        done

        save_config
    fi
}

# Load or Collect Config
load_config

# Convert CPU devices to required format
CPU_FLAGS=""
IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
for DEVICE in "${DEVICES[@]}"; do
    CPU_FLAGS+="--cpu-devices $DEVICE "
done

# Function to start the miner with auto-restart using nohup
start_miner() {
    process_message "Starting Miner in the background with nohup and auto-restart"

    nohup bash -c '
        while true; do
            echo -e "\n\e[42mStarting Miner...\e[0m\n" | tee -a "'"$LOG_FILE"'"
            
            "'"$MINER_BINARY"'" \
                --pool "stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672" \
                '"$CPU_FLAGS"' >> "'"$LOG_FILE"'" 2>&1

            EXIT_CODE=$?
            echo "❌ Miner crashed with exit code $EXIT_CODE. Restarting in 10 seconds..." | tee -a "'"$LOG_FILE"'"
            sleep 10
        done
    ' >> "$LOG_FILE" 2>&1 &

    MINER_PID=$!
    echo "✅ Miner started in the background with PID $MINER_PID."
    echo "Logs are being written to $LOG_FILE"
}

# Display collected configuration
echo -e "\n✅ Configuration Summary:"
echo "Wallet Address: $WALLET_ADDRESS"
echo "Worker Name: $WORKER_NAME"
echo "CPU Devices: $CPU_DEVICES"

# Start the miner
start_miner
