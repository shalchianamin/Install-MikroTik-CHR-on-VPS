#!/bin/bash
set -e

VERSION="$(wget -qO- https://download.mikrotik.com/routeros/NEWESTa7.stable | awk '{print $1}')"

echo "Latest RouterOS stable version: $VERSION"

wget "https://download.mikrotik.com/routeros/${VERSION}/chr-${VERSION}.img.zip" \
    -O chr.img.zip && \

unzip -p chr.img.zip > chr.img && \

STORAGE="$(lsblk -ndo NAME,TYPE | awk '$2=="disk" {print $1; exit}')" && \
echo "STORAGE is $STORAGE" && \

ETH="$(ip route show default | awk '{print $5; exit}')" && \
echo "ETH is $ETH" && \

ADDRESS="$(ip -4 addr show "$ETH" | awk '/scope global/ {print $2; exit}')" && \
echo "ADDRESS is $ADDRESS" && \

GATEWAY="$(ip route show default | awk '{print $3; exit}')" && \
echo "GATEWAY is $GATEWAY" && \

sleep 5 && \

dd if=chr.img of="/dev/$STORAGE" bs=4M conv=fsync status=progress && \

echo "Ok, reboot" && \
echo 1 > /proc/sys/kernel/sysrq && \
echo b > /proc/sysrq-trigger
