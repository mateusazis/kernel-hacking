This time, we will create a QEMU disk image to represent a hard disk drive that will be mounted as our root filesystem. Since it is a disk, we do not need to worry about the amount of data we put in there; just like a real disk, the data will be loaded into memory as needed by the system's processes.

1. Create a QEMU disk image of a certain size (e.g. 10 GB).

    ```bash
    qemu-img create -f qcow2 primary_disk.img 8G
    ```

1.  Create a device file in the host so we can access it.

    ```bash
    sudo modprobe nbd max_part=10
    sudo qemu-nbd -c /dev/nbd0 primary_disk.img
    ```

1.  Partition the disk.

    ```bash
    sudo parted /dev/nbd0 mklabel msdos
    sudo parted /dev/nbd0 mkpart primary ext4 512 8G
    ```

    You can see the disk's partitions via `lsblk /dev/nbd0`.

1.  Format the primary partition.

    It will be available as the block device `/dev/nbd0p1`.

    ```bash
    sudo mkfs.ext4 /dev/nbd0p1
    ```

1.  Mount the disk.

    ```bash
    sudo mount -t ext4 /dev/nbd0p1 /mnt
    ```

    Note: the `-t` parameter is optional; `mount` can often guess the file system type.

    Now that our disk is mounted at the host's `/mnt` path, we can start populating it with useful stuff.

1.  Install Busybox

    Similarly to how we did with `initrd`, let's copy Busybox's binary and symlinks to the new disk.

    First, give yourself ownership of `/mnt` if you need to.

    ```bash
    sudo chown $USER /mnt
    ```

    Then copy the files

    ```bash
    cp -r busybox-1.35.0/_install/{bin,sbin,usr} /mnt
    ```

1.  Create an `init` file in the disk's root as a symlink to `/bin/sh`.

    ```bash
    ln -s /bin/sh /mnt/init
    ```

1.  Our disk is ready. Let's unmount it and disconnect the device.

    ```
    sudo umount /mnt
    sudo qemu-nbd -d /dev/nbd0
    ```

1.  Create a script for `initrd` to switch the root directory to our disk.

    ```bash
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
    ```

    Note that our disk will be mounted as `/dev/sda`, with the primary partition at `/dev/sda1`.

1.  Make that script executable.

    ```bash
    chmod +x busybox-1.35.0/_install/init
    ```

1.  Rebuild `initrd`'s CPIO archive.

    (cd busybox-1.35.0/_install && \
      find . -print0 \
      | cpio --null -ov --format=newc \
      | gzip -9 > initrd.cpio.gz)

1.  Run QEMU.

    This time, add the `-hda` flag to include the disk image as a new drive.


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

1.  When the console starts, you can see that the report disk usage to see that our disk is indeed mounted as root:

    ```bash
    df
    ```

    Prints:

    ```
    Filesystem           1K-blocks      Used Available Use% Mounted on
    /dev/sda1              7099752      4888   6712864   0% /
    none                   1011376         0   1011376   0% /dev
    / # 
    ```
