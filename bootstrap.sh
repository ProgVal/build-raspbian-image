#!/bin/bash

SOURCEDIR=$(dirname $0)

export PYTHONPATH=$SOURCEDIR/vmdebootstrap-raspi3

$SOURCEDIR/vmdebootstrap-raspi3/bin/vmdebootstrap \
    --arch armhf \
    --distribution stretch \
    --mirror http://localhost:3142/ftp.fr.debian.org/debian \
    --image `date +raspbian32-%Y%m%d.img` \
    --size 1000M \
    --bootsize 64M \
    --bootdirfmt=%s/boot/firmware \
    --boottype vfat \
    --root-password raspberry \
    --verbose \
    --no-kernel \
    --no-extlinux \
    --hostname raspberry \
    --foreign /usr/bin/qemu-arm-static \
    --customize "$SOURCEDIR/customize.sh"
