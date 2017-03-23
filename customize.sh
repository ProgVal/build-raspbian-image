#!/bin/bash
set -e

SOURCEDIR="$(dirname $0)"
LINUXSOURCEDIR="$SOURCEDIR/linux-armhf/"
KERNEL_ARCH=arm
ROOTDIR="$1"

# Do not start services during installation.
echo exit 101 > $ROOTDIR/usr/sbin/policy-rc.d
chmod +x $ROOTDIR/usr/sbin/policy-rc.d

# Configure apt.
export DEBIAN_FRONTEND=noninteractive
#cat $SOURCEDIR/raspbian.org.gpg | chroot $ROOTDIR apt-key add -
mkdir -p $ROOTDIR/etc/apt/sources.list.d/
mkdir -p $ROOTDIR/etc/apt/apt.conf.d/
echo "Acquire::http { Proxy \"http://localhost:3142\"; };" > $ROOTDIR/etc/apt/apt.conf.d/50apt-cacher-ng
cp $SOURCEDIR/etc/apt/sources.list $ROOTDIR/etc/apt/sources.list
cp $SOURCEDIR/etc/apt/apt.conf.d/50raspi $ROOTDIR/etc/apt/apt.conf.d/50raspi
chroot $ROOTDIR apt-get update

# Regenerate SSH host keys on first boot.
chroot $ROOTDIR apt-get install -y openssh-server rng-tools
rm -f $ROOTDIR/etc/ssh/ssh_host_*
mkdir -p $ROOTDIR/etc/systemd/system
cp $SOURCEDIR/etc/systemd/system/regen-ssh-keys.service $ROOTDIR/etc/systemd/system/regen-ssh-keys.service
chroot $ROOTDIR systemctl enable regen-ssh-keys

# Configure.
cp $SOURCEDIR/boot/cmdline.txt $ROOTDIR/boot/firmware/cmdline.txt
cp $SOURCEDIR/boot/config.txt $ROOTDIR/boot/firmware/config.txt
cp -r $SOURCEDIR/etc/default $ROOTDIR/etc/default
cp $SOURCEDIR/etc/fstab $ROOTDIR/etc/fstab
cp $SOURCEDIR/etc/modules $ROOTDIR/etc/modules
cp $SOURCEDIR/etc/network/interfaces $ROOTDIR/etc/network/interfaces

FILE="$SOURCEDIR/config/authorized_keys"
if [ -f $FILE ]; then
    echo "Adding authorized_keys."
    mkdir -p $ROOTDIR/root/.ssh/
    cp $FILE $ROOTDIR/root/.ssh/
else
    echo "No authorized_keys, allowing root login with password on SSH."
    sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/" $ROOTDIR/etc/ssh/sshd_config
fi

# Install Raspbian code.
mkdir -p $ROOTDIR/lib/modules
chroot $ROOTDIR apt-get install -y ca-certificates curl binutils git-core kmod
wget https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O $ROOTDIR/usr/local/sbin/rpi-update
chmod a+x $ROOTDIR/usr/local/sbin/rpi-update
SKIP_WARNING=1 SKIP_BACKUP=1 ROOT_PATH=$ROOTDIR BOOT_PATH=$ROOTDIR/boot/firmware $ROOTDIR/usr/local/sbin/rpi-update
rm $ROOTDIR/boot/firmware/kernel*.img

# Install Debian kernel
#wget https://raw.githubusercontent.com/raspberrypi/tools/master/mkimage/imagetool-uncompressed.py -O imagetool-uncompressed.py
#wget https://raw.githubusercontent.com/raspberrypi/tools/master/mkimage/args-uncompressed.txt -O args-uncompressed.txt
#wget https://raw.githubusercontent.com/raspberrypi/tools/master/mkimage/boot-uncompressed.txt -O boot-uncompressed.txt
#chmod a+x imagetool-uncompressed.py
#./imagetool-uncompressed.py $ROOTDIR/boot/vmlinuz-*
#cp kernel.img $ROOTDIR/boot/firmware/kernel.img
#cp kernel.img $ROOTDIR/boot/firmware/kernel7.img
#cp $ROOTDIR/boot/System.map-* $ROOTDIR/boot/firmware/
#cp $ROOTDIR/boot/config-* $ROOTDIR/boot/firmware/
#rm imagetool-uncompressed.py args-uncompressed.txt boot-uncompressed.txt

# Install Raspbian's kernel
$LINUXSOURCEDIR/scripts/mkknlimg $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/Image $ROOTDIR/boot/firmware/kernel7.img
cp $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/dts/*.dtb* $ROOTDIR/boot/firmware/ || true
cp $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/dts/broadcom/*.dtb* $ROOTDIR/boot/firmware/ || true
cp $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtb* $ROOTDIR/boot/firmware/overlays/
cp $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/dts/overlays/README $ROOTDIR/boot/firmware/overlays/

# Install extra packages.
#chroot $ROOTDIR apt-get install -y apt-utils vim nano whiptail netbase less iputils-ping net-tools isc-dhcp-client man-db
#chroot $ROOTDIR apt-get install -y anacron fake-hwclock

# Install other recommended packages.
#apt-get install ntp apt-cron fail2ban needrestart

# Create a swapfile.
#dd if=/dev/zero of=$ROOTDIR/var/swapfile bs=1M count=512
#chroot $ROOTDIR mkswap /var/swapfile
#echo /var/swapfile none swap sw 0 0 >> $ROOTDIR/etc/fstab

# Done.
rm $ROOTDIR/usr/sbin/policy-rc.d
rm $ROOTDIR/etc/apt/apt.conf.d/50apt-cacher-ng
