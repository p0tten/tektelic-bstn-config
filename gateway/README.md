# Tektelic Basic Station - Remote Installer

This tool automates the installation and configuration of **Semtech Basic Station** on Tektelic Kona Gateways (Micro/Macro/Mega).

The script is executed locally from your computer (via Git Bash or Terminal) and manages the entire installation process over SSH. This eliminates the need to manually transfer files or edit configuration files directly on the gateway.

## Features

* **Remote Deployment:** Connects via SSH/SCP to execute the installation automatically from your PC.
* **Official Software:** Downloads and installs the official Tektelic Basic Station package (BSP 7.1.x).
* **Interactive Certificates:** Features a wizard that allows you to paste your ChirpStack certificates directly into the terminal.
* **Port Conflict Resolution:** Automatically changes the UDP port (default `1701`) to prevent conflicts with the built-in legacy Packet Forwarder.
* **CUPS Management:** Provides the option to disable CUPS (`skip_cups = true`) if not required.

## Prerequisites

* A Tektelic Gateway running **BSP 7.1.x**.
* SSH access to the gateway (IP address, username, and password).
* Your ChirpStack certificates ready to be pasted (TC URI, Trust, CRT, Key).

## Usage

1. Open your terminal (Git Bash on Windows or Terminal on Mac/Linux).

2. Navigate to this directory:
   ```bash
   cd gateway

3. Make the script executable (only needed once):
   ```Bash
   chmod +x deploy_gateway.sh

4. Run the installer:
   ```Bash
   ./deploy_gateway.sh

5. Follow the on-screen prompts:
* Enter the **Gateway IP address.**
* Enter the **gateway password** when requested (you may be asked twice: once for file transfer, once for execution).
* Paste your **certificates** when the wizard prompts you.
* Confirm the **port change** and **reboot.**

## Technical Note: Port 1701

Tektelic gateways often ship with a legacy UDP Packet Forwarder running in the background. This service locks access to the LoRa radio hardware. If Basic Station attempts to use the standard port (1700) or starts without stopping the legacy forwarder, a resource conflict occurs, causing Basic Station to crash with HAL_BUSY errors.

This script configures Basic Station to listen on port 1701 instead. This ensures that both services can coexist without conflict, providing a stable installation without requiring risky modifications to system services.

## Troubleshooting

* **SCP/SSH Permission Denied:** Verify your password and ensure SSH is enabled on the gateway.
* **Download Failed:** Ensure the gateway has an active internet connection to download packages from Tektelic's servers.
* **Certificate Errors:** When pasting certificates, ensure you include the full string, including the -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- headers.