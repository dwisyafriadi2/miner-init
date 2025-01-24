@echo off
title Miner Automation Script
setlocal EnableDelayedExpansion

:: Step 1: Download iniminer
echo Downloading iniminer...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-windows-x64.zip', 'iniminer-windows-x64.zip')"

:: Step 2: Extract iniminer
echo Extracting iniminer...
powershell -Command "Expand-Archive -Path 'iniminer-windows-x64.zip' -DestinationPath '.\iniminer' -Force"

:: Step 3: Collect user inputs
set /p WALLET_ADDRESS=Enter your wallet address (e.g., 0x0304f5193FCe6A27e3789c27EE2B9D95177e21A5): 
set /p WORKER_NAME=Enter your worker name (e.g., Worker001): 
set /p CPU_CORES=Enter the number of CPU cores to use (e.g., 1, 2, 3): 

:: Validate CPU_CORES is a number
echo %CPU_CORES%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo Invalid number of CPU cores. Please enter a valid number.
    pause
    exit /b
)

:: Build --cpu-devices argument dynamically
set CPU_DEVICES_ARGS=
for /L %%i in (0,1,%CPU_CORES%-1) do (
    set CPU_DEVICES_ARGS=!CPU_DEVICES_ARGS! --cpu-devices %%i
)

:: Step 4: Navigate to the iniminer folder and run the miner
cd iniminer
echo Starting the miner with your configuration...
echo Command: iniminer.exe --pool stratum+tcp://%WALLET_ADDRESS%.%WORKER_NAME%@pool-b.yatespool.com:32488 %CPU_DEVICES_ARGS%
iniminer.exe --pool stratum+tcp://%WALLET_ADDRESS%.%WORKER_NAME%@pool-b.yatespool.com:32488 %CPU_DEVICES_ARGS%

:: End of script
echo Miner is running. Do not close this window unless you want to stop the miner.
pause
