# Tektelic Basic Station Config Builder & Deployer

This tool automates the configuration and deployment of **Basic Station** for Tektelic LoRaWAN Gateways (e.g., Kona Macro, Kona Micro). 

It is designed for **ChirpStack v4** and features a "Zero-Touch" SSH pipeline that builds, uploads, installs, and configures the gateway in a single pass.

## 🚀 Features

* **SSH Pipeline Deployment:** No need for manual `scp` or `opkg` commands. The script streams the installer directly to the gateway over SSH.
* **Auto-Configuration:** Automatically edits `/etc/default/bstn.toml` to:
  * Disable CUPS (`skip_cups = true`) to prevent boot delays.
  * Set UDP Bind Port to `1701` (required for some setups).
* **Interactive Input:** Paste certificates directly from the ChirpStack web interface.
* **Smart Sanitization:** fixes Windows line-endings (`\r`) and ensures valid certificate formatting.
* **Clean Reboot:** Handles gateway restarts gracefully without hanging your terminal.

## 📋 Prerequisites

* **Linux** or **Git Bash** (Windows).
* A Tektelic Gateway with SSH access (root access required for deployment).
* Gateway credentials generated in ChirpStack.

## 🛠 Usage

1.  **Run the tool:**
    ```bash
    ./build_ipk.sh
    ```

2.  **Input Configuration:**
    * Paste the **Gateway URI** (e.g., `wss://eu868.chirpstack.io:3001`).
    * Paste the **Certificates** (CA, TLS Cert, TLS Key) from ChirpStack.

3.  **Deploy:**
    * The script asks: `Connect to gateway? (y/n)`
    * **Enter SSH Target:** You can now specify full details, e.g.:
      * `root@192.168.1.10`
      * `admin@10.20.30.40`
      * `root@localhost -p 2222` (Reverse Tunnel)

4.  **Reboot:**
    * After installation, the script asks: `Reboot gateway? (y/n)`
    * Choose `y` to apply changes immediately, or `n` to wait.

## 🛡️ Security

* **.gitignore:** This repository includes a `.gitignore` file to prevent sensitive keys (`*.key`, `*.crt`, `*.pem`) from being committed to GitHub.
* **No Temporary Files:** The script cleans up all build artifacts after execution.

## 📝 Troubleshooting

* **"Permission denied" during deploy:**
    Ensure you are using the **root** password. The `admin` user often does not have permissions to run `opkg install` or edit system files.
* **"Connection closed" immediately:**
    This is normal during the reboot phase. The script attempts to exit cleanly, but a fast reboot might drop the connection.