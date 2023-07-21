#! /bin/bash
set -e

sudo apt-get install gawk

wget http://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.xz
tar -xf glibc-2.36.tar.xz

sudo qemu-nbd -c /dev/nbd0 primary_disk.img
sudo mount -t ext4 /dev/nbd0p1 /mnt

mkdir -p glibc_build

(cd glibc_build && ../glibc-2.36/configure --prefix=/mnt)
(cd glibc_build && make -j$(nproc))
(cd glibc_build && make install)

gcc ./03_basic_initrd/init.c -o /mnt/hello_dynamic

mkdir -p /mnt/lib64
ln --symbolic /lib/ld-linux-x86-64.so.2 /mnt/lib64/ld-linux-x86-64.so.2

mkdir -p /mnt/mnt/etc
cat << EOT > /mnt/mnt/etc/ld.so.conf
/lib
EOT

mkdir -p /mnt/etc/init.d
cat << EOT > /mnt/etc/init.d/rcS
#! /bin/sh
ldconfig
EOT
chmod +x /mnt/etc/init.d/rcS

sudo umount /mnt
sudo qemu-nbd -d /dev/nbd0

qemu-system-x86_64 \
    -m 2048M \
    --enable-kvm \
    -cpu host \
    -initrd busybox-1.35.0/_install/initrd.cpio.gz \
    -kernel linux-5.19/arch/x86/boot/bzImage \
    -hda primary_disk.img \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0"
