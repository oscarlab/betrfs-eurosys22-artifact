#!/bin/bash

# Usage: ./change-boot-kernel.sh KERNEL
# This script is used to change which kernel GRUB chooses to boot.
# KERNEL is the label used by GRUB to identify the kernel. Specifically, its format is
# KERNEL_VERSION-CONFIG_LOCALVERSION. For example, 4.19.99-ftfs.

# If you can only access a machine via SSH, you can't access the GRUB
# bootloader menu to choose which kernel to boot. This short helper script
# allows you to change to boot kernel.  After running this script, reboot the
# machine to boot into the new kernel.

# For information about how this script works, refer to:
# https://gist.github.com/msagarpatel/c067fda755aab112d3d3c751662a0267


# parameter validation
set -eux

if [[ $EUID -ne 0 ]]; then
	echo "ERROR: Please run as root."
	exit 1
fi

if [[ $# -ne 1 ]]; then
	echo "Usage: ./change-boot-kernel.sh KERNEL"
	exit 1
fi


# find kernel
KERNEL=$1
GRUB_ENTRY=$(awk -F\' '/menuentry / {print $2}' /boot/grub/grub.cfg | tail -n +2 | grep "$KERNEL\$")
if [[ -z $GRUB_ENTRY ]]; then
	echo "ERROR: $KERNEL not found. Was it correctly installed?"
	exit 1
fi
GRUB_ENTRY="Advanced options for Ubuntu>$GRUB_ENTRY"

# change boot kernel
sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$GRUB_ENTRY\"/g" /etc/default/grub
update-grub
