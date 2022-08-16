Using statically linked binaries for our "hello world" and Busybox is fine for now, but eventually we will need to run dynamically linked binaries. Either because we need to run pre-compiled dynamically linked programs or just because of size (hello world static: 880kb, dynamic: 16kb).

The [GNU C Library](https://www.gnu.org/software/libc/libc.html) provides the basic set of C functions used by most programs (`malloc`, `printf`, `open` etc.) as well as the dynamic linker.

1.  Install extra build dependencies.

    ```bash
    sudo apt-get install gawk
    ```

1.  Download and extract glibc.

    ```bash
    wget http://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.xz
    tar -xf glibc-2.36.tar.xz
    ```

1.  Re-mount the local disk.


    ```bash
    sudo qemu-nbd -c /dev/nbd0 primary_disk.img
    sudo mount -t ext4 /dev/nbd0p1 /mnt
    ```


1.  Configure glibc for compilation. Note that you must configure and build it from a directory other than its source directory. We will also use the `--prefix` parameter to point the installation to our mounted disk.


    ```bash
    mkdir -p glibc_build

    (cd glibc_build && ../glibc-2.36/configure --prefix=/mnt)
    (cd glibc_build && make -j$(nproc))
    (cd glibc_build && make install)
    ```

    You should see folders like `/lib` and `/include` being created.

1.  Let's recompile our "hello world" program as a dynamic binary into the root of the disk.

    ```bash
    gcc initial_filesystem/init.c -o /mnt/hello_dynamic
    ```

    Now, a dynamic binary needs 2 things to run:
    - all of its shared library dependencies to be present on the system;
    - a [dynamic linker](https://man7.org/linux/man-pages/man8/ld.so.8.html): a program that, at invocation time, replaces the references to external symbols in memory with the ones from the shared libraies.

    You can see both with `ldd /mnt/hello_dynamic`. My output: 

    ```
    linux-vdso.so.1 (0x00007ffd5ec4f000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6(0x00007fdfe20a4000)
    /lib64/ld-linux-x86-64.so.2 (0x00007fdfe22e4000)    
    ```

    Where:
    - `linux-vdso.so.1` is provided by the kernel, don't worry about it;
    - `libc.so.6` is the libc. It currently points to the one in my host, not the one that we just compiled, but that's ok.
    - `/lib64/ld-linux-x86-64.so.2` is the dynamic linker.

1.  Let's first satisfy the dynamic linker. GLIBC has one, but it was installed into the disk's `/lib` directory, while my host uses `/lib64`. We can fix it via a simple symlink:

    ```bash
    mkdir -p /mnt/lib64
    ln --symbolic /lib/ld-linux-x86-64.so.2 /mnt/lib64/ld-linux-x86-64.so.2
    ```

    Note: alternatively, we could have invoked the dynamic linker explicitly:

    ```bash
    /lib/ld-linux-x86-64.so.2 /hello_world
    ```

    But of course that is not scalable to every process invocation.

1.  Now, the shared libraries. GLIBC is present in the guest's `/lib`. The documentation for [ld.so](https://man7.org/linux/man-pages/man8/ld.so.8.html) mentions that it looks for shared libraries in the following order:

    1. (deprecated) directories in the DT_RPATH section of the binary
    1. directories in the LD_LIBRARY_PATH environment variable (this is more commonly used for testing/development)
    1. directorioes in the DT_RUNPATH section of the binary
    1. the cache file `/etc/ld.so.cache`. This caches the path of the most common libraries in the system (e.g. `libmath.so => /path/to/libmath.so`).

    We will go with the last option, which is the more permanent one.

    So, first we will create the `/etc/ld.so.config` files, which lists the directories where the guest system's shared libraries can usually be found (just the `/lib` path for now).

    ```bash
    mkdir -p /mnt/mnt/etc
    cat << EOT > /mnt/mnt/etc/ld.so.conf
    /lib
    EOT
    ```

    Note that we put the file on `/mnt/mnt/etc/ld.so.conf` instead of `/mnt/etc/ld.so.conf`. This is needed because our GLIBC was built with the `/mnt` prefix; when we update the cache, by default it will look for a cache file at `/mnt/etc/ld.so.cache`.

1.  Now we need to run `ldconfig` to update the guest's cache. We cannot do it on the host because its `/lib` contains different libraries. Ideally, we should run it whenever libraries are installed/removed. For simplicity, let's use an initialization script (called by the `init` process) to run on every boot.

    ```bash
    mkdir -p /mnt/etc/init.d
    cat << EOT > /mnt/etc/init.d/rcS
    #! /bin/sh
    ldconfig
    EOT
    chmod +x /mnt/etc/init.d/rcS
    ```

1.  We can now unmount the root disk.
    
    ```bash
    sudo umount /mnt
    sudo qemu-nbd -d /dev/nbd0
    ```

1.  And run QEMU exactly as in the last lesson:

    ```bash
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
    ```

1.  Try to run our dynamically-linked binary.

    ```bash
    /hello_dynamic
    ```

    It should execute with no errors!
