#!/bin/zsh

set -e
set -o pipefail

cd "$(dirname $0)"/..

if [ ! -d libimobiledevice ]; then
    git clone https://github.com/libimobiledevice/libimobiledevice.git
fi

pushd libimobiledevice > /dev/null

git clean -fdx
git reset --hard
git pull

popd > /dev/null

pushd ./Sources/MobileBackup/ > /dev/null

rm -rf idevicebackup2.c || true
cp ../../libimobiledevice/tools/idevicebackup2.c .

popd > /dev/null
