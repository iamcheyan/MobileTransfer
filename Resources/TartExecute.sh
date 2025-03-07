#!/bin/zsh

set -e
set -o pipefail

cd "$(dirname "$0")"/..
WORKSPACE=$(pwd)

echo "[*] checking tart..."
TART_VM_TEMPLATE_NAME=$(tart list --format json | jq -r '.[0].Name')

if [[ -z $TART_VM_TEMPLATE_NAME ]]; then
    echo "[!] no tart vm template found"
    exit 1
fi

echo "[*] using template: $TART_VM_TEMPLATE_NAME"

TART_VM_VM_NAME="MobileTransfer-$(date +%Y%m%d%H%M%S)"
echo "[*] using name: $TART_VM_VM_NAME"

tart clone $TART_VM_TEMPLATE_NAME $TART_VM_VM_NAME
EXIT_CLEANUP=1
function cleanup {
    if [[ $EXIT_CLEANUP -eq 1 ]]; then
        EXIT_CLEANUP=0
    else
        return
    fi
    echo "[*] removing vm: $TART_VM_VM_NAME"
    tart stop $TART_VM_VM_NAME 2>/dev/null || true
    tart delete $TART_VM_VM_NAME || true
}
trap cleanup EXIT
trap cleanup INT

echo "[*] start $0 at $(date)"
tart run $TART_VM_VM_NAME --no-graphics &
TART_VM_PID=$!

echo "[*] waiting for boot..."

TART_VM_IP=""
TART_VM_USERNAME="admin"
TART_VM_PASSWORD="admin"

TART_RETRY=60
while [[ -z $TART_VM_IP && $TART_RETRY -gt 0 ]]; do
    echo "[*] waiting for ip address..."
    TART_RETRY=$((TART_RETRY - 1))
    set +e
    TART_VM_IP=$(tart ip $TART_VM_VM_NAME 2>/dev/null)
    set -e
    sleep 1
done

echo "[*] vm has ip: $(tart ip $TART_VM_VM_NAME)"
sshpass -p $TART_VM_PASSWORD \
    ssh -o StrictHostKeyChecking=no \
    $TART_VM_USERNAME@$(tart ip $TART_VM_VM_NAME) \
    "uname -a && mkdir -p ~/Build/"

echo "[*] sending files..."
sshpass -p $TART_VM_PASSWORD \
    scp -o StrictHostKeyChecking=no -r \
    $WORKSPACE \
    $TART_VM_USERNAME@$(tart ip $TART_VM_VM_NAME):~/Build/

echo "[*] opening shell..."
sshpass -p $TART_VM_PASSWORD \
    ssh -o StrictHostKeyChecking=no \
    $TART_VM_USERNAME@$(tart ip $TART_VM_VM_NAME)

echo "[*] done $0 at $(date)"
