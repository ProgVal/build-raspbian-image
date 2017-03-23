#!/bin/bash
NJOBS=4
SOURCEDIR=$(dirname $0)
LINUXSOURCEDIR=$SOURCEDIR/linux-armhf/

#make ARCH=arm64 bcmrpi3_defconfig -C $LINUXSOURCEDIR
#make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs -j $NJOBS -C $LINUXSOURCEDIR
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig -C $LINUXSOURCEDIR
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- Image modules dtbs -j $NJOBS -C $LINUXSOURCEDIR
