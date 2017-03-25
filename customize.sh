#!/bin/bash
set -e

SOURCEDIR="$(dirname $0)"
LINUXSOURCEDIR="$SOURCEDIR/linux/"
KERNEL_ARCH=arm64
ROOTDIR="$1"
NJOBS=10

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
sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/" $ROOTDIR/etc/ssh/sshd_config

# Install Raspbian's kernel
$LINUXSOURCEDIR/scripts/mkknlimg $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/Image $ROOTDIR/boot/firmware/kernel7.img
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$ROOTDIR/ modules_install  -j $NJOBS -C $LINUXSOURCEDIR

# Raspi DTs for arm64
cp $LINUXSOURCEDIR/arch/$KERNEL_ARCH/boot/dts/broadcom/*.dtb* $ROOTDIR/boot/firmware/

# Add the kernel to config.txt:
KERNEL_VERSION=$(LANG=C chroot $ROOTDIR aptitude show linux-image-arm64 | grep "^Depends:" | sed "s/Depends: linux-image-\(.*\)-arm64/\\1/")
cat >>$ROOTDIR/boot/firmware/config.txt <<EOF

# Comment the next three lines to use Raspbian's kernel instead of
# Debian's, which has better hardware support (HDMI, WiFi, Bluetooth).
device_tree=bcm2837-rpi-3-b.dtb
kernel=vmlinuz-$KERNEL_VERSION-arm64
initramfs=initrd.img-$KERNEL_VERSION-arm64
EOF


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
