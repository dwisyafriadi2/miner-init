#!/bin/bash

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

# Function to delete old data
delete_old_data() {
    process_message "Deleting Old Data + Old Binary"
    rm -rf "$HOME_DIR/iniminer-linux-x64*"  
    echo "Old data and binaries have been removed."
}

# Function to fetch the latest binary from GitHub
download_miner() {
    process_message "Downloading the latest Executor binary"
    
    # Fetch the latest release information from GitHub API
    LATEST_RELEASE=$(wget https://api.github.com/repos/Project-InitVerse/miner/releases/latest \
        | grep "browser_download_url.*iniminer-linux-x64" \
        | cut -d '"' -f 4)
    
    if [ -z "$LATEST_RELEASE" ]; then
        echo "Failed to fetch the latest release URL for Linux binary. Exiting."
        exit 1
    fi
    
    echo "Downloading from: $LATEST_RELEASE"
    wget "$LATEST_RELEASE" -O "$HOME_DIR/iniminer-linux-x64"
    
    if [ $? -ne 0 ]; then
        echo "Failed to download the binary. Please check the URL."
        exit 1
    fi
    
    chmod +x "$HOME_DIR/iniminer-linux-x64"
    echo "Download Done"
}


# Function to configure environment with user inputs
configure_environment() {
    # Ask for user inputs
    read -p "Enter your Wallet Address: " WALLET_ADDRESS
    read -p "Enter your Worker Name: " WORKER_NAME
    read -p "Enter CPU Devices (comma-separated, e.g., 1,2): " CPU_DEVICES
    
    # Convert CPU devices to the required format
    CPU_FLAGS=""
    IFS=',' read -ra DEVICES <<< "$CPU_DEVICES"
    for DEVICE in "${DEVICES[@]}"; do
        CPU_FLAGS+="--cpu-devices $DEVICE "
    done

    process_message "Starting Miner with the given configuration in nohup"
    nohup "$HOME_DIR/iniminer-linux-x64" \
        --pool "stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-core-testnet.inichain.com:32672" \
        $CPU_FLAGS > "$HOME_DIR/miner-init/miner.log" 2>&1 &
    
    echo "Miner is running in the background. Logs are saved to $HOME_DIR/miner.log"
}

# Main Script Execution
print_banner
check_root
delete_old_data
download_miner
configure_environment
