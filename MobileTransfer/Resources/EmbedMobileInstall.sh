#!/bin/zsh

set -e
set -o pipefail

echo "    PROJECT_DIR: $PROJECT_DIR"
echo "    CONFIGURATION: $CONFIGURATION"
echo "    CODE_SIGN_IDENTITY: $CODE_SIGN_IDENTITY"
echo "    EXPANDED_CODE_SIGN_IDENTITY_NAME: $EXPANDED_CODE_SIGN_IDENTITY_NAME"
echo "    DEVELOPMENT_TEAM: $DEVELOPMENT_TEAM"

CACHE_DIR="$(pwd)/.cache"
BINARY_CACHE="$CACHE_DIR/MobileInstall"

if [ -n "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
fi
if [ ! -f ".root" ]; then
    exit 1
fi

if [ "$CONFIGURATION" = "Release" ]; then
    rm -rf $CACHE_DIR
fi
mkdir $CACHE_DIR 2> /dev/null || true 

if [ -f "$BINARY_CACHE" ]; then
    echo "Already built the binary as MobileInstall"
else
    echo "Building the binary as MobileInstall..."
    env -i /bin/zsh -c "./MobileInstall/Scripts/compile.sh --export '$BINARY_CACHE'"
fi

APP_PATH="$CODESIGNING_FOLDER_PATH"
AUX_BINARY_DIR="$APP_PATH/Contents/MacOS"
mkdir -p "$AUX_BINARY_DIR"

if [ -n "$EXPANDED_CODE_SIGN_IDENTITY_NAME" ]; then
    echo "[*] overwrite CODE_SIGN_IDENTITY to $EXPANDED_CODE_SIGN_IDENTITY_NAME"
    CODE_SIGN_IDENTITY="$EXPANDED_CODE_SIGN_IDENTITY_NAME"
fi

MOBILE_INSTALL_TARGET="$AUX_BINARY_DIR/MobileInstall"
codesign --force --sign "$CODE_SIGN_IDENTITY" \
    --entitlements "$PROJECT_DIR/MobileTransfer/Entitlements-Subprocess.entitlements" \
    -o runtime \
    "$BINARY_CACHE"

cp "$BINARY_CACHE" "$MOBILE_INSTALL_TARGET"

echo "[*] done $0"
