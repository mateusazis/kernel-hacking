So the kernel wants to run `/init`, the first process with PID 1. It should be on the root file system. We can create a disk image, give it an init process and run it (as a matter of fact, we will do so in the future). But we have a chicken-and-egg problem:

- `/init` is on a disk (let's say the first SCSI disk)
- the disk would be accessible via the block device special file `/dev/sda1`
- this is the only disk in our system, so that's also where we will store our Kernel (let's ignore for a second the fact that this is a VM and things could come from other places).
- The kernel is composed of: kernel binary + dynamically loaded modules
- The driver for the SCSI disk is a kernel module... inside the disk
- Now you need to access the disk to read the module for the driver that gives you access to the disk.

The solution? Load a temporary root filesystem that gives the kernel minimal access to the disk and then switch root to that disk.

That initial filesystem is called **initrd**.

1.  Make a directory for our initial filesystem.

```bash
mkdir initial_filesystem
cd initial_filesystem
``` 

1.  Create a basic hello-world init process:

```bash
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
```

1.  Build it. Note the `-static` flag: we do not want to depend on any shared library! This binary should be able to run on its own.


```bash
gcc -static -o init init.c
```

1.  Build a CPIO archive (similar to a **.tar**) with the init binary at its root.

```bash
find . -print0 \
  | cpio --null -ov --format=newc \
  | gzip -9 > initrd.cpio.gz
```

1.  Run QEMU again, this time passing the `-initrd` flag pointing to the compressed archive.

```bash
qemu-system-x86_64 \
    -m 2048M \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initial_filesystem/initrd.cpio.gz \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0"
```

The logs should eventually mention our `init` binary being executed.

```
[    0.573202] Run /init as init process
Hello world
```
