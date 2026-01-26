# Tektelic Basic Station Config Builder

This tool automates the creation of **Basic Station** configuration packages (`.ipk`) for Tektelic LoRaWAN Gateways (e.g., Kona Macro, Kona Micro). 

It is designed specifically to streamline the deployment of gateways on **ChirpStack v4**, handling certificate formatting, backup file generation, and versioning automatically.

## 🚀 Features

* **Interactive Input:** Copy-paste certificates directly from the ChirpStack web interface (CA, TLS Cert, TLS Key).
* **Auto-Sanitization:** Automatically removes Windows carriage returns (`\r`) and fixes missing newlines that cause connection failures.
* **Backup Generation:** Creates the `.bak` files (e.g., `tc.bak.uri`) that Tektelic firmware often requires to prevent boot loops.
* **Auto-Versioning:** Increments build numbers (v1.0, v1.1...) automatically to ensure `opkg` updates the configuration without requiring force-reinstall.
* **Build Logging:** Tracks build history, timestamps, and target URIs in `build_log.txt`.

## 📋 Prerequisites

* **Linux** or **Git Bash** (Windows).
* A Tektelic Gateway with SSH access.
* Gateway credentials generated in ChirpStack.

## 🛠 Usage

1.  **Run the builder script:**
    ```bash
    ./build_ipk.sh
    ```

2.  **Follow the interactive prompts:**
    * **URI:** Paste the Gateway URI (e.g., `wss://eu868.chirpstack.io:3001`).
    * **Certificates:** Copy the text blocks from ChirpStack for **CA Certificate**, **TLS Certificate**, and **TLS Key**.
    * *Note: Press ENTER on an empty line to confirm each entry.*

3.  **Locate the output:**
    The script will generate a file named `bstn-config-chirpstack.ipk` in the same folder.

## 📦 Installation on Gateway

1.  **Upload the IPK to the gateway:**
    (Replace `root@192.168.1.10` with your gateway's IP)
    ```bash
    scp bstn-config-chirpstack.ipk root@192.168.1.10:/dev/shm/
    ```

2.  **Install via SSH:**
    Log in to the gateway and run:
    ```bash
    opkg install /dev/shm/bstn-config-chirpstack.ipk
    ```
    *Since the script auto-increments the version, `opkg` will update the config even if a previous version exists.*

3.  **Reboot:**
    ```bash
    reboot
    ```

## 🛡️ Security Note

This repository includes a `.gitignore` file to prevent sensitive keys (`*.key`, `*.crt`, `*.pem`) from being committed to the repository. 

**Never force-add your certificates to Git.** Only the builder script and documentation should be version controlled.