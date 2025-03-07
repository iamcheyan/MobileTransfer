#!/bin/zsh

set -e
set -o pipefail

cd "$(dirname $0)"/..

if [ ! -d ideviceinstaller ]; then
    git clone https://github.com/libimobiledevice/ideviceinstaller.git
fi

pushd ideviceinstaller > /dev/null

git clean -fdx
git reset --hard
git pull

popd > /dev/null

pushd ./Sources/MobileInstall/ > /dev/null

rm -rf ideviceinstaller.c || true
cp ../../ideviceinstaller/src/ideviceinstaller.c .

popd > /dev/null
