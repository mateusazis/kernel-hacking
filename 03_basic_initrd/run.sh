#! /bin/bash
set -e


mkdir -p initial_filesystem

gcc -static -o initial_filesystem/init ./03_basic_initrd/init.c

cd initial_filesystem

find . -print0 \
  | cpio --null -ov --format=newc \
  | gzip -9 > initrd.cpio.gz

cd ..

qemu-system-x86_64 \
    -m 2048M \
    -kernel linux-5.19/arch/x86/boot/bzImage \
    -initrd initial_filesystem/initrd.cpio.gz \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0"
