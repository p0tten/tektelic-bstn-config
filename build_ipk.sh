#!/bin/bash

# =======================================================
#   BSTN CONFIG BUILDER & PIPELINE DEPLOYER (v9.1)
# =======================================================

# 1. SETTINGS
PKG_NAME="bstn-config-chirpstack"
OUTPUT_FILENAME="${PKG_NAME}.ipk"
LOG_FILE="build_log.txt"
BUILD_DIR="ipk_build"

# --- REMOTE CONFIGURATION ---
TARGET_FILE="/etc/default/bstn.toml" 
SED_CMD_1="sed -i 's/skip_cups = false/skip_cups = true/g' $TARGET_FILE"
SED_CMD_2="sed -i 's/bind_port = 1700/bind_port = 1701/g' $TARGET_FILE"

# --- VERSIONING ---
if [ -f "$LOG_FILE" ]; then
    LAST_ENTRY=$(tail -n 20 "$LOG_FILE" | grep "Build v" | tail -n 1)
    if [ -z "$LAST_ENTRY" ]; then VERSION="1.0"; else
        CURRENT_VERSION=$(echo "$LAST_ENTRY" | grep -o "v[0-9]*\.[0-9]*" | tr -d 'v')
        IFS='.' read -r -a parts <<< "$CURRENT_VERSION"
        VERSION="${parts[0]}.$((parts[1] + 1))"
    fi
else VERSION="1.0"; fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Build v$VERSION" >> "$LOG_FILE"

# 2. CLEANUP & BUILD ENV
rm -f "$OUTPUT_FILENAME"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/etc/bstn" "$BUILD_DIR/CONTROL"

echo "======================================================="
echo "   BUILD v$VERSION"
echo "======================================================="

# 3. INPUT FUNCTION
read_input() {
    local display_name=$1; local filename=$2
    echo ""; echo ">>> PASTE: '$display_name' (Press ENTER on empty line to save)"
    target_file="$BUILD_DIR/etc/bstn/$filename"
    while IFS= read -r line; do [[ -z "$line" ]] && break; echo "$line" >> "$target_file"; done
    if [ ! -s "$target_file" ]; then echo "FAILED: Empty input"; exit 1; fi
    echo "OK: $filename saved."
}

# URI Input
echo ""; echo ">>> ENTER GATEWAY URI (wss://...):"
read -r URI_INPUT
if [[ "$URI_INPUT" == *"https://"* ]]; then URI_INPUT=${URI_INPUT//https:\/\//}; fi
echo "$URI_INPUT" > "$BUILD_DIR/etc/bstn/tc.uri"
echo "   -> Target URI: $URI_INPUT" >> "$LOG_FILE"

# Cert Inputs
read_input "CA Certificate" "tc.trust"
read_input "TLS Certificate" "tc.crt"
read_input "TLS Key" "tc.key"

# 4. PROCESS FILES
for f in tc.uri tc.trust tc.crt tc.key; do
    filepath="$BUILD_DIR/etc/bstn/$f"
    tmp_file="${filepath}.tmp"; awk '1' "$filepath" | tr -d '\r' > "$tmp_file"; mv "$tmp_file" "$filepath"
    base_name=$(basename "$f" | cut -d. -f1); extension=$(basename "$f" | cut -d. -f2)
    cp "$filepath" "$BUILD_DIR/etc/bstn/${base_name}.bak.${extension}"
    if [ "$extension" == "crt" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/cert.pem"; fi
    if [ "$extension" == "key" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/key.pem"; fi
    if [ "$extension" == "trust" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/trust.pem"; fi
done

# 5. PACKAGING
cat <<EOF > "$BUILD_DIR/CONTROL/control"
Package: $PKG_NAME
Version: $VERSION
Architecture: all
Maintainer: Admin
Description: Config v$VERSION
EOF

cat <<EOF > "$BUILD_DIR/CONTROL/postinst"
#!/bin/sh
chmod 600 /etc/bstn/*.key; chmod 600 /etc/bstn/*.pem
chmod 644 /etc/bstn/tc.uri /etc/bstn/tc.trust /etc/bstn/tc.crt; chmod 644 /etc/bstn/*.bak.*
echo "Config v$VERSION installed."
exit 0
EOF
chmod +x "$BUILD_DIR/CONTROL/postinst"

cd "$BUILD_DIR"; tar -czf ../data.tar.gz etc; cd ..
cd "$BUILD_DIR/CONTROL"; tar -czf ../../control.tar.gz control postinst; cd ../..
echo "2.0" > debian-binary
tar -czf "$OUTPUT_FILENAME" debian-binary data.tar.gz control.tar.gz
rm -rf "$BUILD_DIR" debian-binary data.tar.gz control.tar.gz
echo "SUCCESS! Created: $OUTPUT_FILENAME"

# =======================================================
#   PHASE 2: THE SSH PIPELINE
# =======================================================
echo ""
echo "======================================================="
echo "   ONE-SHOT DEPLOYMENT (SSH PIPE)"
echo "======================================================="
read -p "Connect to gateway? (y/n): " DEPLOY_CONFIRM

if [[ "$DEPLOY_CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter Gateway IP (e.g. 192.168.1.10):"
    read -r GW_IP
    GW_USER="root"
    
    echo ""
    echo "--- STARTING PIPELINE ---"
    echo "Connecting to $GW_IP as $GW_USER..."

    cat "$OUTPUT_FILENAME" | ssh "$GW_USER@$GW_IP" "
        echo '>>> 1. Receiving IPK file...'
        cat > /dev/shm/$OUTPUT_FILENAME
        
        echo '>>> 2. Installing...'
        opkg install /dev/shm/$OUTPUT_FILENAME
        
        echo '>>> 3. Configuring $TARGET_FILE...'
        if [ -f $TARGET_FILE ]; then
            $SED_CMD_1
            $SED_CMD_2
            echo '   - skip_cups set to true'
            echo '   - bind_port set to 1701'
        else
            echo '   WARNING: Config file missing.'
        fi
        
        echo '>>> 4. Rebooting in 3 seconds (Closing connection)...'
        # HÄR ÄR FIXEN: Vi lägger reboot i bakgrunden och väntar lite
        # så att SSH hinner stänga ner snyggt med 'exit 0'
        (sleep 3; reboot) > /dev/null 2>&1 &
        exit 0
    "

    if [ $? -eq 0 ]; then
        echo ""
        echo "--- DEPLOYMENT SUCCESSFUL ---"
        echo "Gateway is restarting now. Give it a minute."
        echo "   [Deploy]: Success $GW_IP" >> "$LOG_FILE"
    else
        echo "--- FAILED ---"
        echo "Error: Access denied or connection failed."
    fi
fi