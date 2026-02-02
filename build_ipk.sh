#!/bin/bash

# =======================================================
#   BSTN DEPLOYER (v11.0 - Clean)
# =======================================================

PKG_NAME="bstn-config-chirpstack"
OUTPUT_FILENAME="${PKG_NAME}.ipk"
LOG_FILE="build_log.txt"
BUILD_DIR="ipk_build"

# --- CONFIGURATION TO APPLY ---
TARGET_FILE="/etc/default/bstn.toml"
CMD_CUPS="sed -i 's/skip_cups = false/skip_cups = true/g' $TARGET_FILE"
CMD_PORT="sed -i 's/bind_port = 1700/bind_port = 1701/g' $TARGET_FILE"

# --- VERSION TRACKING ---
if [ -f "$LOG_FILE" ]; then
    LAST=$(tail -n 20 "$LOG_FILE" | grep "Build v" | tail -n 1)
    [[ -z "$LAST" ]] && VERSION="1.0" || {
        CURRENT=$(echo "$LAST" | grep -o "v[0-9]*\.[0-9]*" | tr -d 'v')
        IFS='.' read -r -a p <<< "$CURRENT"
        VERSION="${p[0]}.$((p[1] + 1))"
    }
else VERSION="1.0"; fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build v$VERSION" >> "$LOG_FILE"

# --- SETUP ---
rm -f "$OUTPUT_FILENAME"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/etc/bstn" "$BUILD_DIR/CONTROL"

echo "--- BUILDING v$VERSION ---"

# --- INPUT HELPERS ---
read_input() {
    local name=$1; local file=$2
    echo ""; echo ">>> PASTE: $name (ENTER on empty line to save)"
    target="$BUILD_DIR/etc/bstn/$file"
    while IFS= read -r line; do [[ -z "$line" ]] && break; echo "$line" >> "$target"; done
    [ ! -s "$target" ] && { echo "Error: Empty input for $file"; exit 1; }
}

# --- COLLECT DATA ---
echo ""; echo ">>> ENTER URI (wss://...):"
read -r URI
[[ "$URI" == *"https://"* ]] && URI=${URI//https:\/\//}
echo "$URI" > "$BUILD_DIR/etc/bstn/tc.uri"
echo "Target: $URI" >> "$LOG_FILE"

read_input "CA Certificate"  "tc.trust"
read_input "TLS Certificate" "tc.crt"
read_input "TLS Key"         "tc.key"

# --- PROCESS FILES (Sanitize + Backup) ---
for f in tc.uri tc.trust tc.crt tc.key; do
    src="$BUILD_DIR/etc/bstn/$f"
    # Remove Windows CRLF
    awk '1' "$src" | tr -d '\r' > "${src}.tmp" && mv "${src}.tmp" "$src"
    # Create .bak copy for Tektelic fallback
    base=$(basename "$f" | cut -d. -f1); ext=$(basename "$f" | cut -d. -f2)
    cp "$src" "$BUILD_DIR/etc/bstn/${base}.bak.${ext}"
done

# --- PACKAGE ---
cat <<EOF > "$BUILD_DIR/CONTROL/control"
Package: $PKG_NAME
Version: $VERSION
Architecture: all
Maintainer: Admin
Description: Config v$VERSION
EOF

cat <<EOF > "$BUILD_DIR/CONTROL/postinst"
#!/bin/sh
chmod 600 /etc/bstn/*.key
chmod 644 /etc/bstn/tc.uri /etc/bstn/tc.trust /etc/bstn/tc.crt /etc/bstn/*.bak.*
exit 0
EOF
chmod +x "$BUILD_DIR/CONTROL/postinst"

cd "$BUILD_DIR"; tar -czf ../data.tar.gz etc; cd ..
cd "$BUILD_DIR/CONTROL"; tar -czf ../../control.tar.gz control postinst; cd ../..
echo "2.0" > debian-binary
tar -czf "$OUTPUT_FILENAME" debian-binary data.tar.gz control.tar.gz
rm -rf "$BUILD_DIR" debian-binary data.tar.gz control.tar.gz

echo "Success: $OUTPUT_FILENAME created."

# --- DEPLOYMENT ---
echo ""; read -p "Deploy to gateway? (y/n): " DO_DEPLOY
if [[ "$DO_DEPLOY" =~ ^[Yy]$ ]]; then
    echo "Examples: root@192.168.1.10 | admin@10.20.1.5 | root@localhost -p 2222"
    read -p "SSH Target: " TARGET

    echo "--- Deploying to $TARGET ---"
    cat "$OUTPUT_FILENAME" | ssh $TARGET "
        echo '> Receiving & Installing...'
        cat > /dev/shm/$OUTPUT_FILENAME
        opkg install /dev/shm/$OUTPUT_FILENAME

        echo '> Configuring...'
        if [ -f $TARGET_FILE ]; then
            $CMD_CUPS
            $CMD_PORT
            echo '  - Cups disabled, Port 1701 set.'
        else
            echo '  Warning: Config file not found.'
        fi
    "

    if [ $? -eq 0 ]; then
        echo "   [Deploy]: Success ($TARGET)" >> "$LOG_FILE"
        echo ""; read -p "Reboot gateway now? (y/n): " DO_REBOOT
        if [[ "$DO_REBOOT" =~ ^[Yy]$ ]]; then
            ssh $TARGET "(sleep 2; reboot) >/dev/null 2>&1 & exit 0"
            echo "Rebooting..."
        fi
    else
        echo "Error: Connection failed."
    fi
fi