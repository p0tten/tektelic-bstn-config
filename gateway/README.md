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