#!/bin/bash

SOURCEDIR=$(dirname $0)

export PYTHONPATH=$SOURCEDIR/vmdebootstrap-raspi3

$SOURCEDIR/vmdebootstrap-raspi3/bin/vmdebootstrap \
    --arch arm64 \
    --distribution stretch \
    --mirror http://localhost:3142/ftp.fr.debian.org/debian \
    --image `date +raspbian64-%Y%m%d.img` \
    --size 1500M \
    --bootsize 64M \
    --bootdirfmt=%s/boot/firmware \
    --boottype vfat \
    --root-password raspberry \
    --verbose \
    --package raspi3-firmware \
    --package aptitude \
    --no-extlinux \
    --hostname raspberry \
    --foreign /usr/bin/qemu-aarch64-static \
    --debootstrapopts="components=main,non-free" \
    --customize "$SOURCEDIR/customize.sh"
