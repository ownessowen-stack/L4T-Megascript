#!/usr/bin/env bash
set -euo pipefail

# config dirs and download
DOWNLOAD_URL="https://raw.githubusercontent.com/ownessowen-stack/SteamARMtargz/main/steam-automagic-2026-04-17.tar.gz"
STEAM_DIR="$HOME/.local/share/Steam"
STEAM_LINK_DIR="$HOME/.steam"
DESKTOP_DIR="$HOME/Desktop"

# Files to extract from tar.gz
TARBALL_PREFIX="automagic-2026-04-17"
SCRIPT1="steamrt-boot.sh"
SCRIPT2="start-steam.sh"

# Helper function for error messages
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Step 1: install Box64
echo "=============================================="
echo "Installing Box64"
echo "=============================================="
sleep 1
# Add Box64 repository
echo "Adding Box64 repository..."
sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list || error_exit "Failed to download box64.list"

# Add GPG key
echo "Adding Box64 GPG key..."
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg || error_exit "Failed to add GPG key"

# Update package lists and install Box64
echo "Updating package lists and installing box64..."
sudo apt update || error_exit "apt update failed"
sudo apt install box64-tegrax1 -y || error_exit "Failed to install box64"

echo "Box64 installation completed."
sleep 1

# Step 1: Create Steam directory
echo "=============================================="
echo "Steam installation started..."
echo "=============================================="
sleep 1
echo "Creating Steam directory at $STEAM_DIR (if not exists)..."
mkdir -p "$STEAM_DIR"

# Step 2: Download the archive
TEMP_ARCHIVE="$(mktemp)"
echo "Downloading archive from GitHub..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$TEMP_ARCHIVE" "$DOWNLOAD_URL" || error_exit "Download failed with curl."
elif command -v wget >/dev/null 2>&1; then
    wget -O "$TEMP_ARCHIVE" "$DOWNLOAD_URL" || error_exit "Download failed with wget."
else
    error_exit "Neither curl nor wget is installed. Please install one of them."
fi

# Step 3: Extract the two scripts into Steam directory
echo "Extracting $SCRIPT1 and $SCRIPT2 from archive..."
tar -xzf "$TEMP_ARCHIVE" -C "$STEAM_DIR" \
    --strip-components=1 \
    "$TARBALL_PREFIX/$SCRIPT1" \
    "$TARBALL_PREFIX/$SCRIPT2" \
    || error_exit "Extraction failed."

# Clean up temporary archive
rm -f "$TEMP_ARCHIVE"

# --- Step 5: Run start-steam.sh (Should result in symlink errors) ---
echo "Running $SCRIPT2 "
set +e  # Temporarily disable exit-on-error
"$STEAM_DIR/$SCRIPT2"
SCRIPT2_EXIT_CODE=$?
set -e  # Re-enable exit-on-error

if [ $SCRIPT2_EXIT_CODE -ne 0 ]; then
    echo "NOTE: $SCRIPT2 exited with code $SCRIPT2_EXIT_CODE. This is expected."
else
    echo "$SCRIPT2 completed successfully (unexpected, reinstall?)."
fi

# Step 6: Create symlinks in ~/.steam/
echo "Creating symlinks in $STEAM_LINK_DIR..."
mkdir -p "$STEAM_LINK_DIR"
ln -sfn "$STEAM_DIR" "$STEAM_LINK_DIR/steam"
ln -sfn "$STEAM_DIR" "$STEAM_LINK_DIR/root"
echo "Symlinks created: ~/.steam/steam -> $STEAM_DIR"
echo "Symlinks created: ~/.steam/root -> $STEAM_DIR"

# Step 7: Create desktop shortcut
if [ -d "$DESKTOP_DIR" ]; then
    DESKTOP_FILE="$DESKTOP_DIR/SteamRuntime.desktop"
    echo "Creating desktop shortcut at $DESKTOP_FILE..."
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Steam
Comment=Launch Steam in terminal
Exec=$STEAM_DIR/$SCRIPT1
Icon=steam
Terminal=true
Type=Application
Categories=Game;
EOF
    chmod +x "$DESKTOP_FILE"
    echo "Desktop shortcut created."
else
    echo "Warning: Desktop directory not found at $DESKTOP_DIR. You will have to run Steam manually"
fi

# --- Step 8: Final message ---
echo ""
echo "=============================================="
echo "Steam installation finished successfully!"
echo "Box64 has been installed."
echo "A desktop shortcut to Steam' has been placed on your desktop."
echo "If shortcut creation failed, run it manually from:"
echo "  $STEAM_DIR/$SCRIPT1"
echo "=============================================="
