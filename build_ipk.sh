#!/bin/bash

# 1. Settings
PKG_NAME="bstn-config-chirpstack"
OUTPUT_FILENAME="${PKG_NAME}.ipk"
LOG_FILE="build_log.txt"
BUILD_DIR="ipk_build"

# --- VERSION & LOGGING ---
CODENAMES=("NEON" "CYBER" "IRON" "STEEL" "VOID" "QUANTUM" "SOLAR" "LUNAR" "SHADOW" "ECHO")
SUFFIXES=("EAGLE" "WOLF" "STORM" "FALCON" "VORTEX" "PHANTOM" "RANGER" "SPECTRE" "CORE" "LINK")
RAND1=${CODENAMES[$RANDOM % ${#CODENAMES[@]}]}
RAND2=${SUFFIXES[$RANDOM % ${#SUFFIXES[@]}]}
CODENAME="${RAND1}_${RAND2}"

if [ -f "$LOG_FILE" ]; then
    LAST_ENTRY=$(tail -n 20 "$LOG_FILE" | grep "Build v" | tail -n 1)
    if [ -z "$LAST_ENTRY" ]; then
        VERSION="1.0"
    else
        CURRENT_VERSION=$(echo "$LAST_ENTRY" | grep -o "v[0-9]*\.[0-9]*" | tr -d 'v')
        IFS='.' read -r -a parts <<< "$CURRENT_VERSION"
        VERSION="${parts[0]}.$((parts[1] + 1))"
    fi
else
    VERSION="1.0"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Start log entry
echo "----------------------------------------------------------------" >> "$LOG_FILE"
echo "[$TIMESTAMP] Build v$VERSION : Codename $CODENAME" >> "$LOG_FILE"

# 2. Setup
rm -f "$OUTPUT_FILENAME"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/etc/bstn"
mkdir -p "$BUILD_DIR/CONTROL"

echo "======================================================="
echo "   BUILD v$VERSION ($CODENAME)"
echo "======================================================="
echo "Instructions: Copy text from ChirpStack browser window."
echo "              Paste here, then press ENTER on an empty line."
echo "-------------------------------------------------------"

# 3. INPUT FUNCTION WITH LOGGING
read_input() {
    local display_name=$1
    local filename=$2
    
    echo ""
    echo ">>> COPY FROM CHIRPSTACK: '$display_name'"
    echo "    (Paste content below -> Press ENTER on empty line to save)"
    
    target_file="$BUILD_DIR/etc/bstn/$filename"
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then break; fi
        echo "$line" >> "$target_file"
    done
    
    if [ ! -s "$target_file" ]; then
        echo "WARNING: Input for $display_name seems empty!"
        echo "   -> $display_name: FAILED (Empty)" >> "$LOG_FILE"
        exit 1
    else
        echo "OK: Saved as $filename"
        # Log success (but not the secret content)
        echo "   -> $display_name: Loaded OK" >> "$LOG_FILE"
    fi
}

# --- STEP 1: URI ---
echo ""
echo ">>> ENTER GATEWAY URI:"
echo "    (Copy 'UDP bind' or construct wss://...)"
read -r URI_INPUT
echo "$URI_INPUT" > "$BUILD_DIR/etc/bstn/tc.uri"
# Log the URI specifically
echo "   -> Target URI: $URI_INPUT" >> "$LOG_FILE"


# --- STEP 2: CERTIFICATES ---
# Log that we are starting cert input
echo "   [Certificates]" >> "$LOG_FILE"

read_input "CA Certificate" "tc.trust"
read_input "TLS Certificate" "tc.crt"
read_input "TLS Key" "tc.key"

# 4. Processing & Backups
echo ""
echo "--- Processing Files ---"

for f in tc.uri tc.trust tc.crt tc.key; do
    filepath="$BUILD_DIR/etc/bstn/$f"
    if [ ! -f "$filepath" ]; then echo "ERROR: Missing $f"; exit 1; fi

    # Sanitize
    tmp_file="${filepath}.tmp"
    awk '1' "$filepath" | tr -d '\r' > "$tmp_file"
    mv "$tmp_file" "$filepath"
    
    # Create Backups & PEMs
    base_name=$(basename "$f" | cut -d. -f1)
    extension=$(basename "$f" | cut -d. -f2)
    cp "$filepath" "$BUILD_DIR/etc/bstn/${base_name}.bak.${extension}"
    
    if [ "$extension" == "crt" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/cert.pem"; fi
    if [ "$extension" == "key" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/key.pem"; fi
    if [ "$extension" == "trust" ]; then cp "$filepath" "$BUILD_DIR/etc/bstn/trust.pem"; fi
done

# 5. Packaging
cat <<EOF > "$BUILD_DIR/CONTROL/control"
Package: $PKG_NAME
Version: $VERSION
Architecture: all
Maintainer: Admin
Description: Config ($CODENAME).
EOF

cat <<EOF > "$BUILD_DIR/CONTROL/postinst"
#!/bin/sh
chmod 600 /etc/bstn/*.key
chmod 600 /etc/bstn/*.pem
chmod 644 /etc/bstn/tc.uri /etc/bstn/tc.trust /etc/bstn/tc.crt
chmod 644 /etc/bstn/*.bak.*
echo "Configuration v$VERSION ($CODENAME) installed."
exit 0
EOF
chmod +x "$BUILD_DIR/CONTROL/postinst"

cd "$BUILD_DIR"; tar -czf ../data.tar.gz etc; cd ..
cd "$BUILD_DIR/CONTROL"; tar -czf ../../control.tar.gz control postinst; cd ../..
echo "2.0" > debian-binary
tar -czf "$OUTPUT_FILENAME" debian-binary data.tar.gz control.tar.gz

rm -rf "$BUILD_DIR" debian-binary data.tar.gz control.tar.gz

# FINAL LOGGING
echo "   [Result]: SUCCESS" >> "$LOG_FILE"

echo ""
echo "SUCCESS! Created: $OUTPUT_FILENAME (v$VERSION)"
echo "Details logged to $LOG_FILE"