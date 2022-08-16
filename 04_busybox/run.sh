#! /bin/bash
wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2
tar -xf busybox-1.35.0.tar.bz2


(cd busybox-1.35.0 && make defconfig)
(cd busybox-1.35.0 && make LDFLAGS="--static" -j$(nproc))
(cd busybox-1.35.0 && make LDFLAGS="--static" install)

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
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0 rdinit=/bin/sh"
