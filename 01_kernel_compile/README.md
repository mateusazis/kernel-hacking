1.  Download the latest kernel

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.19.tar.xz
tar -xzf linux-5.19.tar.xz
```

2.  Move into the kernel's directory

```bash
cd linux-5.19
```

3.  Setup a minimal kernel configuration.

```bash
make defconfig
```

4.  Build it!

Use the `-j` flag to control the number of parallel tasks to use. It greatly improves build time. A reasonable default is 1.5x the number of available CPUs.


```bash
make -j$(nproc)
```

The last line of the output will show where the compiled kernel image is:

```
Kernel: arch/x86/boot/bzImage is ready  (#8)
```

5.  Leave the kernel directory so we can continue from there.

```bash
cd ..
```
