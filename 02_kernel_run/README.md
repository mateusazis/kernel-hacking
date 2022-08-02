Install QEMU so we can run a Virtual Machine:

```bash
sudo apt-get install qemu-system
```

Launch the kernel:

```bash
qemu-system-x86_64 \
    -m 2048M \
    -kernel linux-5.19/arch/x86/boot/bzImage \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0"
```


Congratulations, you are runnning your kernel! The first line of kernel logging should contain its version (later available in `/proc/version`) and the second one has its arguments.

```
SeaBIOS (version 1.15.0-1)

iPXE (https://ipxe.org) 00:03.0 CA00 PCI2.10 PnP PMM+7FF8B340+7FECB340 CA00


Booting from ROM..
[    0.000000] Linux version 5.19.0-rc7-g70664fc10c0d (azis@azis-ubuntu) (gcc (Ubuntu 11.2.0-19ubuntu1) 11.2.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #8 SMP PREEMPT_DYNAMIC Mon Jul 25 19:55:05 PDT 2022
[    0.000000] Command line: console=ttyS0
```

Later on, it stops on a failure. The kernel wants to run /init on the root file system, but it can't find that system. We will explore what do in the next part.

```
[    1.167369] /dev/root: Can't open blockdev
[    1.167730] VFS: Cannot open root device "(null)" or unknown-block(0,0): error -6
[    1.168341] Please append a correct "root=" boot option; here are the available partitions:
[    1.169032] 0800        10485760 sda 
[    1.169034]  driver: sd
[    1.169554] 0b00         1048575 sr0 
[    1.169555]  driver: sr
[    1.170082] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
[    1.170757] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 5.19.0-rc7-g70664fc10c0d #1
[    1.171375] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.15.0-1 04/01/2014
[    1.172052] Call Trace:
[    1.172268]  <TASK>
[    1.172451]  dump_stack_lvl+0x34/0x48
[    1.172764]  panic+0x102/0x27b
[    1.173034]  mount_block_root+0x15e/0x1f8
[    1.173372]  prepare_namespace+0x136/0x165
[    1.173720]  kernel_init_freeable+0x202/0x20d
[    1.174085]  ? rest_init+0xc0/0xc0
[    1.174378]  kernel_init+0x11/0x120
[    1.174670]  ret_from_fork+0x22/0x30
[    1.174967]  </TASK>
[    1.175233] Kernel Offset: 0x2d800000 from 0xffffffff81000000 (relocation range: 0xffffffff80000000-0xffffffffbfffffff)
[    1.176104] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
```

To quit, press `CTRL+A C` to move to the QEMU monitor and then `q` and `ENTER`.
