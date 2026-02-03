#!/bin/bash

# --- LOCAL CONFIGURATION ---
REMOTE_USER="admin"

# --- STEP 1: SELECT GATEWAY ---
echo " "
echo "=================================================="
echo "   Remote Basic Station Installer (Tektelic)"
echo "=================================================="
read -p "Enter Gateway IP address: " TARGET_IP

if [ -z "$TARGET_IP" ]; then
    echo "No IP provided. Exiting."
    exit 1
fi

echo " "
echo "Connecting to $TARGET_IP..."
echo "Note: You may be asked for the gateway password twice (once for SCP, once for SSH)."
echo " "

# --- STEP 2: CREATE PAYLOAD SCRIPT ---
# We create the script locally to send it over.
# 'EOF' (quoted) ensures variables are not expanded locally, but on the gateway.
cat > payload_installer.sh << 'EOF'
#!/bin/bash

# --- REMOTE SCRIPT CONFIG ---
BSTN_SCRIPT_URL="http://74.3.134.37:32370//config/script_for_bstn.zip"
FEED_URL="http://74.3.134.37:32370/universal/71161/bsp/"
OAM_URL="ssl://lorawan-oam.tektelic.com:8883"
CONFIG_FILE="/etc/default/bstn.toml"
NEW_PORT=1701

# Check for root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Script must be run as root (sudo)."
    exit 1
fi

echo " "
echo "============================================="
echo "   Tektelic Basic Station All-in-One Installer"
echo "============================================="
echo "Running on: $(hostname)"
echo " "

# --- STEP 1: DOWNLOAD TOOLS ---
cd /home/admin || exit
echo "--- Step 1: Downloading tools ---"

curl -k -L "$BSTN_SCRIPT_URL" --output bstn.zip

if [ ! -f "bstn.zip" ]; then
    echo "ERROR: Could not download bstn.zip. Check internet connection."
    exit 1
fi

unzip -o bstn.zip > /dev/null
rm bstn.zip
chmod a+x *.sh *.py

echo "--- Running toggle_ns_oam.sh (Auto-selecting Option 2 + URL) ---"
printf "2\n$OAM_URL\n" | ./toggle_ns_oam.sh

# --- STEP 2: INSTALL SOFTWARE ---
echo " "
echo "--- Step 2: Installing Basic Station package ---"
echo "src/gz bsp $FEED_URL" > /etc/opkg/snmpManaged-feed.conf
opkg update
opkg install tektelic-bstn
rm /etc/opkg/snmpManaged-feed.conf
echo "Software installation complete."

# --- STEP 3: CERTIFICATES ---
echo " "
echo "============================================="
echo "--- Step 3: Certificate Configuration ---"
echo "You will now run the standard Tektelic certificate wizard."
echo "Please PASTE your ChirpStack certificates when prompted."
echo "NOTE: When asked for 'CUPS URI', press Enter to skip (we will disable it in Step 4)."
echo "============================================="
echo "Press Enter to launch movecerts.sh..."
read -r
./movecerts.sh

# --- STEP 4: CONFIGURATION ADJUSTMENTS ---
echo " "
echo "============================================="
echo "--- Step 4: Configuration Adjustments ---"
echo "Target file: $CONFIG_FILE"
echo " "

# 4a. Disable CUPS (skip_cups = true)
read -p "Do you want to disable CUPS (set skip_cups = true)? (y/n): " disable_cups
if [[ $disable_cups == [yY] || $disable_cups == [yY][eE][sS] ]]; then
    if [ -f "$CONFIG_FILE" ]; then
        # Check if the parameter already exists
        if grep -q "skip_cups" "$CONFIG_FILE"; then
            # Replace existing line
            sed -i 's/.*skip_cups.*/skip_cups = true/' "$CONFIG_FILE"
        else
            # Append to end of file
            echo "" >> "$CONFIG_FILE"
            echo "skip_cups = true" >> "$CONFIG_FILE"
        fi
        echo "OK: 'skip_cups = true' set in config."
    else
        echo "WARNING: Config file not found."
    fi
else
    echo "Skipping CUPS disable."
fi

# 4b. Change Port?
echo " "
read -p "Do you want to change the UDP port to $NEW_PORT (Recommended)? (y/n): " change_port
if [[ $change_port == [yY] || $change_port == [yY][eE][sS] ]]; then
    if [ -f "$CONFIG_FILE" ]; then
        # Replace 1700 with 1701 for both 'port' and 'udp_port' keys
        sed -i "s/port = 1700/port = $NEW_PORT/g" "$CONFIG_FILE"
        sed -i "s/udp_port = 1700/udp_port = $NEW_PORT/g" "$CONFIG_FILE"
        echo "OK: Port changed to $NEW_PORT."
    else
        echo "WARNING: Config file not found."
    fi
else
    echo "Skipping port change."
fi

# --- STEP 5: REBOOT ---
echo " "
echo "============================================="
read -p "Installation complete. Reboot gateway now? (y/n): " reboot_confirm
if [[ $reboot_confirm == [yY] || $reboot_confirm == [yY][eE][sS] ]]; then
    echo "Rebooting..."
    tektelic_reset
else
    echo "Done. Please reboot manually later."
fi

# --- END OF REMOTE SCRIPT ---
EOF

# --- STEP 3: UPLOAD SCRIPT ---
echo "Uploading installer to gateway..."
scp payload_installer.sh ${REMOTE_USER}@${TARGET_IP}:/tmp/install_bstn.sh

if [ $? -ne 0 ]; then
    echo "ERROR: SCP failed. Check IP and password."
    rm payload_installer.sh
    exit 1
fi

# --- STEP 4: EXECUTE SCRIPT ---
echo "Executing installer..."
# -t forces TTY allocation so interactive prompts work
ssh -t ${REMOTE_USER}@${TARGET_IP} "chmod +x /tmp/install_bstn.sh && sudo /tmp/install_bstn.sh"

# Cleanup local file
rm payload_installer.sh

echo " "
echo "Process finished."