#!/bin/bash

# Usage: ./build-and-install-linux.sh VERSION [PATCH_FILE]
# This script is used to build the version, VERSION, of the kernel.org stable Linux repo.
# VERSION can be the name of any version in the stable Linux repo. For example, 4.19.99.
# The optional PATCH_FILE can be used to build a patched version of the kernel.
# This should be a path to a standard patch file that can be applied using git-apply(1).


# Parse commandline arguments and perform initial checks
set -eux

if [[ $# -ne 1 && $# -ne 2 ]]; then
	echo "Usage: ./build-and-install-linux.sh VERSION [PATCH_FILE]"
	echo "Incorrect number of parameters."
	exit 1
fi

VERSION=$1

if [[ $# -eq 2 ]]; then
	PATCH_FILE="$(realpath $2)"
	if [ ! -f $PATCH_FILE ]; then
		echo "$PATCH_FILE is missing or not a regular file."
		exit 1
	fi
	# PATCH_NAME is used to name the kernel since the EuroSys experiments use three different kernels!
	PATCH_NAME="-$(basename $PATCH_FILE .patch)"
else
	# define variables so set -u doesn't cause a error
	PATCH_FILE=
	PATCH_NAME=
fi
LINUX_DIR="linux-${VERSION}${PATCH_NAME}"

# copy unpatched kernel (if available) to speed up compilation of patched version
# TODO: is not worth the trouble since the patched config is always modified due to LOCALVERSION.
#       Might be worth it if we pass EXTRAVERSION as a parameter to make commands instead. Try this.
# if [[ -n $PATCH_NAME && -d linux-$VERSION ]]; then
# 	cp -a linux-$VERSION $LINUX_DIR
# fi


# download kernel
# We use tarballs instead of the stable git repo since we might want to switch between kernels.
# Since we use tarballs, we don't need to rebuild and reinstall the kernel each time we want to
# switch, but this comes at the cost of additional disk usage.
if [[ ! -d $LINUX_DIR ]]; then
	wget --no-clobber https://cdn.kernel.org/pub/linux/kernel/v${VERSION:0:1}.x/linux-${VERSION}.tar.xz
	mkdir $LINUX_DIR
	tar -xf linux-$VERSION.tar.xz -C $LINUX_DIR --strip-components 1
fi
cd $LINUX_DIR


# Apply patch if present
if [[ -f $PATCH_FILE ]]; then
	patch -p1 < $PATCH_FILE
fi


# Build kernel
if [[ ! -f .config ]]; then
	cp ../config-4.19.99 .config
fi
./scripts/config --set-val CONFIG_LOCALVERSION \"$PATCH_NAME\"
make olddefconfig
make -j$(nproc --all)


# Install kernel
# Note: this might not select the installed kernel as the boot kernel.
# Refer to another script in this directory to choose the boot kernel.
sudo make INSTALL_MOD_STRIP=1 modules_install
sudo make install
