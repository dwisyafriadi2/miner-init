#!/bin/bash

# Start Miner Script

# Function to print the banner
print_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
}

# Function to display process message with sleep
process_message() {
    echo -e "\n\e[42m$1...\e[0m\n" && sleep 1
}

# Print the banner
print_banner

# Variables
HOME_DIR=$(eval echo ~$USER)
MINER_BINARY="$HOME_DIR/iniminer-linux-x64"
LOG_FILE="$HOME_DIR/miner.log"
WALLET_ADDRESS="INPUT_YOUR_ADDRESS"
WORKER_NAME="VPS-1"

# Input rentang perangkat CPU (misalnya "0,40" untuk perangkat dari 0 hingga 40)
CPU_RANGE="0,40"

# Pisahkan input rentang menjadi START dan END
IFS=',' read -r START END <<< "$CPU_RANGE"

# Generate CPU devices range from START to END
CPU_FLAGS=""
for ((i=$START; i<=$END; i++)); do
    CPU_FLAGS+="--cpu-devices $i "
done

# Check if the miner binary exists
process_message "Checking Miner Binary"
if [ ! -f "$MINER_BINARY" ]; then
    echo " ^}^l Miner binary not found at $MINER_BINARY. Please run the setup script first."
    exit 1
fi

# Function to start the miner and log it
start_miner() {
    process_message "Starting Miner in the background with nohup and auto-restart"
    nohup bash -c "
        while true; do
            echo -e '\n\e[42mStarting Miner...\e[0m\n' | tee -a '$LOG_FILE'
            
            '$MINER_BINARY' \
                --pool 'stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@https://a.yatespool.com' \
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


    process_message "Starting Miner with nohup"
    nohup "$MINER_BINARY" \
        --pool "stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672" \
        $CPU_FLAGS > "$LOG_FILE" 2>&1 &
    MINER_PID=$!
    echo " ^|^e Miner started successfully. Logs are saved in $LOG_FILE"
    echo "Miner process ID: $MINER_PID"
}

# Loop to ensure the miner is always running
while true; do
    # Start the miner
    start_miner

    # Wait for the miner to start and ensure it's running
    sleep 5

    # Check if the miner is running
    if ps -p $MINER_PID > /dev/null; then
        echo "Miner is running, monitoring logs..."
        tail -f "$LOG_FILE" &  # Start tailing the log
        wait $MINER_PID         # Wait for the miner to finish
    else
        echo " ^}^l Miner stopped or disconnected. Restarting..."
    fi

    # Restart the miner after 5 seconds if it stops
    sleep 5
done
