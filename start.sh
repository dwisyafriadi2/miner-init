#!/bin/bash

# ---------------------------
# Miner Start Script with Auto-Restart and Connection Suspension Handling
# ---------------------------

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process messages
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Print the banner
print_banner

# ---------------------------
# Variables
# ---------------------------
HOME_DIR=$(eval echo ~$USER)
MINER_BINARY="$HOME_DIR/iniminer-linux-x64"
LOG_FILE="$HOME_DIR/miner-init/miner.log"
CONFIG_FILE="$HOME_DIR/miner-init/miner_config.conf"

# Ensure miner-init directory exists
mkdir -p "$HOME_DIR/miner-init"

# ---------------------------
# Check if Binary Exists
# ---------------------------
process_message "Checking Miner Binary"
if [ ! -f "$MINER_BINARY" ]; then
    echo "❌ Miner binary not found at $MINER_BINARY. Please run the setup script first."
    exit 1
fi

# ---------------------------
# Save User Inputs to Config
# ---------------------------
save_config() {
    echo "WALLET_ADDRESS=$WALLET_ADDRESS" > "$CONFIG_FILE"
    echo "WORKER_NAME=$WORKER_NAME" >> "$CONFIG_FILE"
    echo "CPU_DEVICES=$CPU_DEVICES" >> "$CONFIG_FILE"
}

# ---------------------------
# Load Configuration
# ---------------------------
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

# Load Configuration
load_config

# ---------------------------
# Format CPU Devices
# ---------------------------
CPU_FLAGS=""
IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
for DEVICE in "${DEVICES[@]}"; do
    CPU_FLAGS+="--cpu-devices $DEVICE "
done

# ---------------------------
# Start Miner with nohup and Auto-Restart
# ---------------------------
start_miner() {
    process_message "Starting Miner in the background with nohup and auto-restart"

    nohup bash -c "
        while true; do
            echo -e '\n\e[42mStarting Miner...\e[0m\n' | tee -a '$LOG_FILE'
            
            '$MINER_BINARY' \
                --pool 'stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672' \
                $CPU_FLAGS >> '$LOG_FILE' 2>&1 &

            MINER_PID=\$!
            echo \"✅ Miner started with PID \$MINER_PID.\" | tee -a '$LOG_FILE'

            # Monitor the log for suspension messages
            tail -F '$LOG_FILE' | while read LINE; do
                if echo \"\$LINE\" | grep -q 'No connection. Suspend mining'; then
                    echo \"⚠️ Connection suspended detected. Restarting miner...\" | tee -a '$LOG_FILE'
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
# Display Configuration Summary
# ---------------------------
echo -e "\n✅ **Configuration Summary:**"
echo "Wallet Address: $WALLET_ADDRESS"
echo "Worker Name: $WORKER_NAME"
echo "CPU Devices: $CPU_DEVICES"
echo "Log File: $LOG_FILE"

# ---------------------------
# Start Miner
# ---------------------------
start_miner
