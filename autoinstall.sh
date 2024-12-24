#!/bin/bash

# ---------------------------
# Miner Auto-Install and Start Script with Auto-Restart
# ---------------------------

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process message
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Function to check root/sudo and set home directory
check_root() {
    process_message "Checking root privileges"
    if [ "$EUID" -ne 0 ]; then
        HOME_DIR="/home/$USER"
        echo "Running as user. Files will be saved to $HOME_DIR."
    else
        HOME_DIR="/root"
        echo "Running as root. Files will be saved to $HOME_DIR."
    fi
}

# Function to prepare directories
prepare_directories() {
    process_message "Preparing directories"
    MINER_DIR="$HOME_DIR/miner-init"
    mkdir -p "$MINER_DIR"
    echo "✅ Directory $MINER_DIR is ready."
}

# Variables
MINER_DIR="$HOME_DIR/miner-init"
MINER_BINARY="$MINER_DIR/iniminer-linux-x64"
LOG_FILE="$MINER_DIR/miner.log"
CONFIG_FILE="$MINER_DIR/miner_config.conf"

# Function to delete old data
delete_old_data() {
    process_message "Deleting Old Data + Old Binary"
    rm -rf "$MINER_BINARY" "$LOG_FILE" "$CONFIG_FILE"
    echo "✅ Old data and binaries have been removed."
}

# Function to fetch the latest binary from GitHub
download_miner() {
    process_message "Downloading the latest Executor binary"
    
    # Fetch the latest release information from GitHub API
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/Project-InitVerse/miner/releases/latest \
        | grep "browser_download_url.*iniminer-linux-x64" \
        | cut -d '"' -f 4)
    
    if [ -z "$LATEST_RELEASE" ]; then
        echo "❌ Failed to fetch the latest release URL for Linux binary. Exiting."
        exit 1
    fi
    
    echo "Downloading from: $LATEST_RELEASE"
    wget "$LATEST_RELEASE" -O "$MINER_BINARY"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download the binary. Please check the URL."
        exit 1
    fi
    
    chmod +x "$MINER_BINARY"
    echo "✅ Download Done"
}

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
        read -p "Enter your Wallet Address: " WALLET_ADDRESS
        read -p "Enter your Worker Name: " WORKER_NAME
        read -p "Enter CPU Devices (comma-separated, e.g., 1,2): " CPU_DEVICES
        save_config
    fi
}

# Function to start the miner with nohup and auto-restart
start_miner() {
    process_message "Starting Miner in the background with nohup and auto-restart"

    nohup bash -c '
        while true; do
            echo -e "\n\e[42mStarting Miner...\e[0m\n" | tee -a "'"$LOG_FILE"'"
            
            "'"$MINER_BINARY"'" \
                --pool "stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672" \
                '"$CPU_FLAGS"' >> "'"$LOG_FILE"'" 2>&1

            EXIT_CODE=$?
            echo "❌ Miner crashed with exit code $EXIT_CODE. Restarting in 5 seconds..." | tee -a "'"$LOG_FILE"'"
            sleep 5
        done
    ' >> "$LOG_FILE" 2>&1 &

    MINER_PID=$!
    echo "✅ Miner started in the background with PID $MINER_PID."
    echo "Logs are being written to $LOG_FILE"
}

# Main Script Execution
print_banner
check_root
prepare_directories
delete_old_data
download_miner
load_config

# Convert CPU devices to required format
CPU_FLAGS=""
IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
for DEVICE in "${DEVICES[@]}"; do
    CPU_FLAGS+="--cpu-devices $DEVICE "
done

start_miner
