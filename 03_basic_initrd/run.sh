#! /bin/bash


mkdir initial_filesystem
cd initial_filesystem

cat << EOT >> init.c
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv) {
  printf("Hello world\n");
  while (1) {
    sleep(99999);
  }
  return 0;
}
EOT

gcc -static -o init init.c

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
