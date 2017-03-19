#!/bin/bash

SOURCEDIR=$(dirname $0)

vmdebootstrap \
    --arch armhf \
    --distribution stretch \
    --mirror http://localhost:3142/ftp.fr.debian.org/debian \
    --image `date +raspbian-%Y%m%d.img` \
    --size 2000M \
    --bootsize 64M \
    --boottype vfat \
    --root-password raspberry \
    --verbose \
    --no-kernel \
    --no-extlinux \
    --hostname raspberry \
    --foreign /usr/bin/qemu-arm-static \
    --customize "$SOURCEDIR/customize.sh"
