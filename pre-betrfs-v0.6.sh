#!/bin/bash

# This script installs the kernel required for benchmarking BetrFS v0.6: Linux 4.19.99-betrfs-v0.6.

set -eux

./build-and-install-linux.sh 4.19.99 betrfs-v0.6.patch
./change-boot-kernel.sh 4.19.99-betrfs-v0.6

echo -e "\n[BetrFS] Installed and selected Linux v4.19.99-betrfs-v0.6 as boot kernel.
         Run 'sudo reboot' to boot the new kernel.\n"
