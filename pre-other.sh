#!/bin/bash

# This script installs the kernel required for benchmarking other file systems: Linux 5.9.15.
# It also installs ZFS.

set -eux

./build-and-install-linux.sh 5.9.15


# build and install ZFS
KDIR="$PWD/linux-5.9.15"
cd $KDIR
make prepare
cd -

wget https://github.com/openzfs/zfs/releases/download/zfs-0.8.6/zfs-0.8.6.tar.gz
tar xf zfs-0.8.6.tar.gz
cd zfs-0.8.6
sh autogen.sh
./configure \
	--prefix=/ \
	--libdir=/lib \
	--includedir=/usr/include \
	--datarootdir=/usr/share \
	--enable-linux-builtin=yes \
	--with-linux=$KDIR \
	--with-linux-obj=$KDIR

sed -i '/^rm.*\.gitignore/d' copy-builtin
./copy-builtin $KDIR
make -j$(nproc --all)
sudo make install
cd -


# rebuild and reinstall kernel, but this time with ZFS support
cd $KDIR
make olddefconfig
./scripts/config --set-val CONFIG_ZFS y
make -j$(nproc --all)
sudo make INSTALL_MOD_STRIP=1 modules_install
sudo make install
cd -


./change-boot-kernel.sh 5.9.15


echo -e "\n[BetrFS] Installed and selected Linux v5.9.15 as boot kernel.
         Run 'sudo reboot' to boot the new kernel.\n"
