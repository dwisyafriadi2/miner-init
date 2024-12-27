#!/bin/bash

# ---------------------------
# Miner Installer and Runner Script
# ---------------------------

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process messages
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Function to check root/sudo and set the home directory
check_root() {
    process_message "Checking root privileges"
    if [ "$EUID" -ne 0 ]; then
        HOME_DIR="/home/$USER"
        echo "✅ Running as user. Files will be saved to $HOME_DIR."
    else
        HOME_DIR="/root"
        echo "✅ Running as root. Files will be saved to $HOME_DIR."
    fi

    MINER_BINARY="$HOME_DIR/iniminer-linux-x64"
    LOG_FILE="$HOME_DIR/miner-init/miner.log"
}

# Function to delete old binaries and data
delete_old_data() {
    process_message "Deleting Old Data + Old Binary"
    rm -rf "$MINER_BINARY" "$HOME_DIR/iniminer-linux-x64*" "$LOG_FILE"
    mkdir -p "$HOME_DIR/miner-init"
    echo "✅ Old data and binaries have been removed."
}

# Function to download the latest binary from GitHub
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
    
    echo "📥 Downloading from: $LATEST_RELEASE"
    wget "$LATEST_RELEASE" -O "$MINER_BINARY"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download the binary. Please check the URL."
        exit 1
    fi
    
    chmod +x "$MINER_BINARY"
    echo "✅ Download Complete."
}

# Function to configure environment with user inputs
configure_environment() {
    process_message "Configuring Environment"

    # Collect user input with validation
    while [[ -z "$WALLET_ADDRESS" ]]; do
        read -p "Enter your Wallet Address: " WALLET_ADDRESS
    done
    
    while [[ -z "$WORKER_NAME" ]]; do
        read -p "Enter your Worker Name: " WORKER_NAME
    done
    
    while [[ -z "$CPU_DEVICES" ]]; do
        read -p "Enter CPU Devices (comma-separated, e.g., 0,1,2): " CPU_DEVICES
    done

    # Convert CPU devices to the required format
    CPU_FLAGS=""
    IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
    for DEVICE in "${DEVICES[@]}"; do
        CPU_FLAGS+="--cpu-devices $DEVICE "
    done

    # Save configuration
    CONFIG_FILE="$HOME_DIR/miner-init/miner_config.conf"
    echo "WALLET_ADDRESS=$WALLET_ADDRESS" > "$CONFIG_FILE"
    echo "WORKER_NAME=$WORKER_NAME" >> "$CONFIG_FILE"
    echo "CPU_DEVICES=$CPU_DEVICES" >> "$CONFIG_FILE"
    echo "✅ Configuration saved to $CONFIG_FILE."
}

# Function to start the miner in the background with nohup
start_miner() {
    process_message "Starting Miner with nohup and auto-restart"

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
    echo "📄 Logs are saved to $LOG_FILE"
}

# Function to display configuration summary
show_summary() {
    echo -e "\n✅ **Configuration Summary:**"
    echo "Wallet Address: $WALLET_ADDRESS"
    echo "Worker Name: $WORKER_NAME"
    echo "CPU Devices: $CPU_DEVICES"
    echo "Miner Log: $LOG_FILE"
}

# ---------------------------
# Main Script Execution
# ---------------------------
print_banner
check_root
delete_old_data
download_miner
configure_environment
show_summary
start_miner
