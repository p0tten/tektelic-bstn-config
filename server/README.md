# Tektelic Basic Station Deployer

Automated tool to build, configure, and deploy **Basic Station** (ChirpStack v4) on Tektelic Gateways.

## Features
* **Zero-Touch Deploy:** Uploads and installs via SSH piping (no SCP needed).
* **Auto-Config:** Sets `skip_cups=true` and `bind_port=1701`.
* **Sanitization:** Fixes Windows line-endings and creates required `.bak` files.
* **Versioning:** Auto-increments package version to force updates.

## Usage

1.  **Run:**
    ```bash
    ./build_ipk.sh
    ```

2.  **Input:**
    * Paste the **Gateway URI** (e.g. `wss://eu868.chirpstack.io:3001`).
    * Paste Certificates from ChirpStack (CA, TLS Cert, TLS Key).
    * *Tip: Press ENTER on an empty line to confirm input.*

3.  **Deploy:**
    * Enter SSH Target (e.g. `root@192.168.1.10` or `root@localhost -p 2222`).
    * Choose whether to reboot immediately after installation.

## Security
* **.gitignore:** Prevents keys (`*.key`, `*.crt`) from being committed to git.
* **Cleanup:** No temporary build files are left on disk.