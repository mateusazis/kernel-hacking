#! /bin/bash

sudo apt-get install qemu-system

qemu-system-x86_64 \
    -m 2048M \
    -kernel linux-5.19/arch/x86/boot/bzImage \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0"
