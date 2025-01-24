#!/bin/bash

# ---------------------------
# Miner Start Script with Auto-Update, Pool Selection, Auto-Restart, and Connection Suspension Handling
# ---------------------------

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process messages
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Function to download the latest miner binary
download_latest_miner() {
    process_message "Downloading the latest Miner binary"

    # Fetch the latest release information from GitHub API
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/Project-InitVerse/miner/releases/latest)
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -oP '"browser_download_url": "\K(.*?)(?=")' | grep 'iniminer-linux-x64')

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "❌ Failed to fetch the latest release URL for Linux binary. Exiting."
        exit 1
    fi

    echo "Downloading from: $DOWNLOAD_URL"
    curl -L "$DOWNLOAD_URL" -o "$MINER_BINARY"

    if [ $? -ne 0 ]; then
        echo "❌ Failed to download the binary. Please check the URL."
        exit 1
    fi

    chmod +x "$MINER_BINARY"
    echo "✅ Download completed and binary is executable."
}

# Function to save user inputs to config
save_config() {
    echo "WALLET_ADDRESS=$WALLET_ADDRESS" > "$CONFIG_FILE"
    echo "WORKER_NAME=$WORKER_NAME" >> "$CONFIG_FILE"
    echo "CPU_DEVICES=$CPU_DEVICES" >> "$CONFIG_FILE"
    echo "POOL_ADDRESS=$POOL_ADDRESS" >> "$CONFIG_FILE"
}

# Function to load configuration
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

        echo -e "\nSelect Mining Pool:"
        echo "1) Pool 1: pool-a.yatespool.com:31588"
        echo "2) Pool 2: pool-b.yatespool.com:32488"
        while [[ -z "$POOL_SELECTION" ]]; do
            read -p "Enter the number of the pool you want to use (1 or 2): " POOL_SELECTION
            case $POOL_SELECTION in
                1)
                    POOL_ADDRESS="pool-a.yatespool.com:31588"
                    ;;
                2)
                    POOL_ADDRESS="pool-b.yatespool.com:32488"
                    ;;
                *)
                    echo "Invalid selection. Please enter 1 or 2."
                    POOL_SELECTION=""
                    ;;
            esac
        done

        save_config
    fi
}

# Function to start the miner with auto-restart and connection suspension handling
start_miner() {
    process_message "Starting Miner in the background with nohup and auto-restart"

    nohup bash -c "
        while true; do
            echo -e '\n\e[42mStarting Miner...\e[0m\n' | tee -a '$LOG_FILE'

            '$MINER_BINARY' \
                --pool 'stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@${POOL_ADDRESS}' \
                $CPU_FLAGS >> '$LOG_FILE' 2>&1 &

            MINER_PID=\$!
            echo \"✅ Miner started with PID \$MINER_PID.\" | tee -a '$LOG_FILE'

            # Monitor the log for suspension messages
            tail -F '$LOG_FILE' | while read LINE; do
                if echo \"\$LINE\" | grep -q 'No connection. Suspend mining'; then
                    echo \"⚠️ Connection suspension detected. Restarting miner...\" | tee -a '$LOG_FILE'
                    kill \$MINER_PID
                    wait \$MINER_PID 2>/dev/null
                    break
                fi
            done

            echo '❌ Miner crashed or connection suspended. Restarting in 10 seconds...' | tee -a '$LOG_FILE'
            sleep 10
        done
    " >> "$LOG_FILE" 2>&1 &

    MINER_PID=$!
    echo "✅ Miner started in the background with PID $MINER_PID."
    echo "📄 Logs are being written to $LOG_FILE"
}

# ---------------------------
# Main Script Execution
# ---------------------------

# Print the banner
print_banner

# Variables
HOME_DIR=$(eval echo ~$USER)
MINER_BINARY="$HOME_DIR/iniminer-linux-x64"
LOG_FILE="$HOME_DIR/miner-init/miner.log"
CONFIG_FILE="$HOME_DIR/miner-init/miner_config.conf"

# Ensure miner-init directory exists
mkdir -p "$HOME_DIR/miner-init"

# Download the latest miner binary
download_latest_miner

# Load or collect configuration
load_config

# Format CPU devices
CPU_FLAGS=""
IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
for DEVICE in "${DEVICES[@]}"; do
    CPU_FLAGS+="--cpu-devices $DEVICE "
done

# Display configuration summary
echo -e "\n✅ **Configuration Summary:**"
echo "Wallet Address: $WALLET_ADDRESS"
echo "Worker Name: $WORKER_NAME"
echo "CPU Devices: $CPU_DEVICES"
echo "Pool Address: $POOL_ADDRESS"
echo "Log File: $LOG_FILE"

# Start the miner
start_miner
