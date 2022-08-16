#! /bin/bash

qemu-img create -f qcow2 primary_disk.img 8G

sudo modprobe nbd max_part=10
sudo qemu-nbd -c /dev/nbd0 primary_disk.img

sudo parted /dev/nbd0 mklabel msdos
sudo parted /dev/nbd0 mkpart primary ext4 512 8G

sudo mkfs.ext4 /dev/nbd0p1

sudo mount -t ext4 /dev/nbd0p1 /mnt

sudo chown $USER /mnt

cp -r busybox-1.35.0/_install/{bin,sbin,usr} /mnt

ln -s /bin/busybox /mnt/init

sudo umount /mnt
sudo qemu-nbd -d /dev/nbd0

cat << EOT > busybox-1.35.0/_install/init
#! /bin/sh

mkdir -p /proc /sys /dev /mnt

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t ext4 /dev/sda1 /mnt

mkdir -p /mnt/dev /mnt/proc /mnt/sys
mount /proc /mnt/proc
mount /sys /mnt/sys
mount /dev /mnt/dev

exec switch_root /mnt /init
EOT

chmod +x busybox-1.35.0/_install/init

(cd busybox-1.35.0/_install && \
  find . -print0 \
  | cpio --null -ov --format=newc \
  | gzip -9 > initrd.cpio.gz)

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
