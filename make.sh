#!/bin/zsh

set -e
set -o pipefail

cd "$(dirname "$0")"
WORKSPACE=$(pwd)

CLEAN=0
while [[ $# -gt 0 ]]; do
    case $1 in
    --clean)
        CLEAN=1
        shift
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

if [[ $CLEAN -eq 1 ]]; then
    git clean -fdx -f
    git reset --hard
fi

echo "[*] start $0 at $(date)"

rm -rf $WORKSPACE/MobileTransfer.app 2>/dev/null || true

echo "[*] update submodules..."
./MobileBackup/Scripts/update.sh
./MobileInstall/Scripts/update.sh

echo "[*] resolve dependencies..."
xcodebuild -resolvePackageDependencies \
    -workspace MobileTransfer.xcworkspace \
    -scheme MobileTransfer \
    | xcbeautify

echo "[*] building..."
xcodebuild -scheme MobileTransfer \
    -workspace MobileTransfer.xcworkspace \
    -derivedDataPath Build \
    -configuration Release \
    -destination 'platform=macOS' \
    -archivePath Archive \
    clean archive \
    | xcbeautify

echo "[*] exporting..."
xcodebuild \
    -archivePath Archive.xcarchive \
    -exportOptionsPlist MobileTransfer/Resources/ExportOptions.plist \
    -exportPath Build/MobileTransfer \
    -allowProvisioningUpdates \
    -exportArchive \
    | xcbeautify

echo "[*] searching for app..."
APP_PATH=$(realpath Build/MobileTransfer/*.app)

echo "[*] product at $APP_PATH"

echo "[*] notarizing..."
/usr/bin/ditto -c -k --keepParent \
    "$APP_PATH" \
    "Build/MobileTransfer.zip"

xcrun notarytool submit \
    --keychain-profile "NotaryProfile@砍砍" \
    --wait \
    "Build/MobileTransfer.zip"

rm -rf "Build/MobileTransfer.zip"

echo "[*] stapling ticket..."
xcrun stapler staple $APP_PATH

echo "[*] copying..."
cp -a $APP_PATH $WORKSPACE/MobileTransfer.app

echo "[*] done $0 at $(date)"
