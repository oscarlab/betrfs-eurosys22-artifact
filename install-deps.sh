#!/bin/bash

# This scripts takes no parameters.

# Use this script to install all the dependencies required to:
#   - build Linux, BetrFS, and ZFS.
#   - build the programs needed for running benchmarks.
#   - run benchmarks.

# Array of dependencies
# Duplicates are intentional so we can track precisely which dependencies are needed for what.
DEPS=(
	# build Linux kernel
	git
	bison
	flex
	libelf-dev
	libssl-dev
	ncurses-dev

	# build BetrFS
	# LFS may be needed for older versions of BetrFS
	git-lfs
	gcc-7
	g++-7
	valgrind
	zlib1g-dev
	make
	cmake

	# build ZFS
	wget
	libtool
	uuid-dev
	libblkid-dev
	autoconf
	liblz4-tool

	# tools for other file systems
	# There are probably packages we could enumerate for the other file systems, but the tools we
	# need appear to be come with the stock Ubuntu 18.04 distribution.
	f2fs-tools

	# statistics
	ministat

	# build dovecot for mailserver benchmark
	wget
	make
	libssl-dev
	libpam-dev
	autoconf
	libtool
	python

	# build filebench
	wget
	make
	bison
	flex
)

set -eux

if [[ $EUID -ne 0 ]]; then
	echo "ERROR: Please run as root."
	exit 1
fi

apt-get update
apt-get install -y ${DEPS[*]}

# set default gcc and g++ versions so everything is built using the same compiler
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 50
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 50

# download betrfs repo
REPO=betrfs
if [[ ! -d $REPO ]]; then
	git clone https://github.com/oscarlab/$REPO.git
fi

# Checkout any BetrFS v0.6 branch, but not master since master doesn't have the
# EuroSys22 benchmarks scripts.
cd $REPO
git checkout eurosys22/query-path-opt
cd -

# set some configuration variables
# You should still check fs-info.sh to make sure they're correct. At least one
# variable (sb_dev) must be set manually.
dummy_dev=$(losetup -f)
sed -i "s/^dummy_dev=.*/dummy_dev=\"${dummy_dev//\//\\/}\"/g" $REPO/benchmarks/fs-info.sh
sed -i "s/^CUR_MNTPNT=.*/CUR_MNTPNT=\"${PWD//\//\\/}\"/g" $REPO/benchmarks/fs-info.sh

# build and install dovecot, and setup mailboxes
if ! command -v dovecot &> /dev/null; then
	cd $REPO/benchmarks/macro/mailserver
	./setup.sh
	cd -
fi

# build and install filebench
if ! command -v filebench &> /dev/null; then
	cd $REPO/benchmarks/macro/filebench
	./install.sh
	cd -
fi

echo -e "\n[BetrFS] Installed dependencies\n"
