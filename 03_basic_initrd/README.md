So the kernel wants to run `/init`, the process with PID 1. It should be on the root file system. We can create a disk image, place an `init` binary inside and let the kernel start it (as a matter of fact, we will do so later). But we have a chicken-and-egg problem:

- `/init` is on a disk (let's say the first SCSI disk).
- the disk would be accessible via the block device special file `/dev/sda1`.
- this is the only disk in our system, so that's also where we will store our Kernel (let's ignore for a second the fact that this is a VM and things could come from other places).
- The kernel is composed of: kernel binary + dynamically loaded modules.
- The driver for the SCSI disk is in a kernel module... inside the disk.
- Now you need to access the disk to read the module for the driver that gives you access to the disk.

The solution? Load a temporary root filesystem that gives the kernel minimal access to the disk and then switch root to that disk.

That initial filesystem is called **initrd**. You can find Ubuntu's in `/boot/initrd.img` (a symlink to a versioned image). It will get decrompressed and loaded into the system's RAM, so it is desirable to keep it small specially for resource-constrained devices.

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

1.  Build it. Note the `-static` flag: we do not want to depend on any shared library! Our system has no libc nor a [dynamic linker](https://man7.org/linux/man-pages/man8/ld.so.8.html). Trying to run a binary with dynamic linking would yield a cryptic "No such file" (ENOENT) error.


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
        -kernel linux-5.19/arch/x86/boot/bzImage \
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
