Now that we have something running, we can load up the real root filesystem from a hard drive and start running applications from there.

But doing so in C can be quite exhausting. Instead, let's install a minimal shell and set of running tools so we can do it via a shell script. We will use [BusyBox](https://www.busybox.net/) for that.

1.  Download Busybox and extract Busybox's source code

    ```bash
    wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2
    tar -xf busybox-1.35.0.tar.bz2
    ```

1.  Configure it
    ```bash
    (cd busybox-1.35.0 && make defconfig)
    ```

    Build Busybox and install it. Note the `--static` flag passed to the linker. This will have a similar effect to the one given to our "hello world" `init`.\* 

    ```
    (cd busybox-1.35.0 && LDFLAGS=--static make -j$(nproc))
    (cd busybox-1.35.0 && make install)
    ```

1.  `busybox-1.35.0/_install` will now contain a directory structure similar to a initrd filesystem. Let's build the CPIO archive:


    ```bash
    (cd busybox-1.35.0/_install && \
      find . -print0 \
      | cpio --null -ov --format=newc \
      | gzip -9 > initrd.cpio.gz)
    ```

1.  Run QEMU:

    ```bash
    qemu-system-x86_64 \
        -m 2048M \
        --enable-kvm \
        -cpu host \
        -initrd busybox-1.35.0/_install/initrd.cpio.gz \
        -kernel linux-5.19/arch/x86/boot/bzImage \
        -nographic \
        -serial mon:stdio \
        -append "console=ttyS0"
    ```

    And you will get an error like

    ```
    [    1.185550] /dev/root: Can't open blockdev
    [    1.185936] VFS: Cannot open root device "(null)" or unknown-block(0,0): error -6
    [    1.186588] Please append a correct "root=" boot option; here are the available partitions:
    [    1.187323] 0b00         1048575 sr0 
    [    1.187326]  driver: sr
    [    1.187890] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
    [    1.188612] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 5.19.0-rc7-g70664fc10c0d #8
    [    1.189264] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.15.0-1 04/01/2014
    [    1.189990] Call Trace:
    [    1.190223]  <TASK>
    [    1.190415]  dump_stack_lvl+0x34/0x48
    [    1.190744]  panic+0x102/0x27b
    [    1.191026]  mount_block_root+0x15e/0x1f8
    [    1.191388]  prepare_namespace+0x136/0x165
    [    1.191744]  kernel_init_freeable+0x202/0x20d
    [    1.192133]  ? rest_init+0xc0/0xc0
    [    1.192457]  kernel_init+0x11/0x120
    [    1.192770]  ret_from_fork+0x22/0x30
    [    1.193091]  </TASK>
    [    1.193368] Kernel Offset: 0xe600000 from 0xffffffff81000000 (relocation range: 0xffffffff80000000-0xffffffffbfffffff)
    [    1.194285] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
    ```

    We have seen this before. The kernel wants to load `/init` but there is no such file in our initrd. We can either create a symlink to `/bin/sh` or just point the kernel's `rdinit=` param to `/bin/sh`.

    ```bash
    qemu-system-x86_64 \
        -m 2048M \
        --enable-kvm \
        -cpu host \
        -initrd busybox-1.35.0/_install/initrd.cpio.gz \
        -kernel linux-5.19/arch/x86/boot/bzImage \
        -nographic \
        -serial mon:stdio \
        -append "console=ttyS0 rdinit=/bin/sh"
    ```

    Now you will see other errors in the log:

    ```
    [    0.588286] Run /bin/sh as init process                                                                                               │ Library m is needed, can't exclude it (yet)
    /bin/sh: can't access tty; job control turned off                                                                                        │ Library resolv is needed, can't exclude it (yet)
    / # [    1.196645] input: ImExPS/2 Generic Explorer Mouse as /devices/platform/i8042/serio1/input/input3                                 │Final link with: m resolv
                                                        
    ```

    Done! Now you have an minimally working shell!


    ## Note: 
    \* If you do not wish to statically link Busybox, then you will also need some additional shared libraries and the dynamic linker in your initrd. You can copy them from the host to the `_install` directory (see below).

    ```bash
    mkdir -p busybox-1.35.0/_install/{lib,lib64}
    cp /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libresolv.so.2 /lib/x86_64-linux-gnu/libc.so.6 busybox-1.35.0/_install/lib/x86_64-linux-gnu
    cp /lib64/ld-linux-x86-64.so.2 busybox-1.35.0/_install/lib64
    ```
