#!/bin/bash
set -e

# Install unzip if needed
if command -v unzip >/dev/null 2>&1; then
    UNZIP="unzip"
elif command -v busybox >/dev/null 2>&1 && busybox unzip >/dev/null 2>&1; then
    UNZIP="busybox unzip"
else
    echo "unzip not found. Installing..."

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y unzip
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache unzip
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y unzip
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install unzip
    else
        echo "ERROR: Cannot install unzip automatically."
        exit 1
    fi

    UNZIP="unzip"
fi

# Find latest RouterOS v7 stable release
VERSION="$(wget -qO- https://download.mikrotik.com/routeros/NEWESTa7.stable | awk '{print $1}')"

echo "Latest RouterOS stable version: $VERSION"

# Download CHR
wget "https://download.mikrotik.com/routeros/${VERSION}/chr-${VERSION}.img.zip" \
    -O chr.img.zip

# Extract image
$UNZIP -p chr.img.zip > chr.img

# Find first disk
STORAGE="$(lsblk -ndo NAME,TYPE | awk '$2=="disk" {print $1; exit}')"
echo "STORAGE is $STORAGE"

# Find active/default network interface
ETH="$(ip route show default | awk '{print $5; exit}')"
echo "ETH is $ETH"

# IP address
ADDRESS="$(ip -4 addr show "$ETH" | awk '/scope global/ {print $2; exit}')"
echo "ADDRESS is $ADDRESS"

# Gateway
GATEWAY="$(ip route show default | awk '{print $3; exit}')"
echo "GATEWAY is $GATEWAY"

echo
echo "RouterOS version: $VERSION"
echo "Disk: /dev/$STORAGE"
echo "Interface: $ETH"
echo "Address: $ADDRESS"
echo "Gateway: $GATEWAY"
echo
echo "Writing RouterOS image in 5 seconds..."
sleep 5

dd if=chr.img of="/dev/$STORAGE" bs=4M conv=fsync status=progress

sync

echo "Ok, reboot"

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
