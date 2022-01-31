#!/bin/bash

# This script installs the kernel required for benchmarking BetrFS: Linux 4.19.99.

set -eux

./build-and-install-linux.sh 4.19.99
./change-boot-kernel.sh 4.19.99

echo -e "\n[BetrFS] Installed and selected Linux v4.19.99 as boot kernel.
         Run 'sudo reboot' to boot the new kernel.\n"
