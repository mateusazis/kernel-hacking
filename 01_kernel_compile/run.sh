#! /bin/bash
set -e

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.19.tar.xz
tar -xf linux-5.19.tar.xz

cd linux-5.19
make defconfig
make -j$(nproc)
cd ..
