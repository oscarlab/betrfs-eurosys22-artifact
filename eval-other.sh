#!/bin/bash

# set up
set -eux
ARTIFACT_DIR=$PWD
TIME=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p results
if [[ "$(uname -r)" != "5.9.15" ]]; then
	echo "ERROR: correct kernel version is not running."
	exit 1
fi

FILE_SYSTEMS=(
	ext4
	btrfs
	xfs
	f2fs
	zfs
)

cd betrfs/benchmarks
# Only the last version of BetrFS v0.6 measures all benchmarks, so checkout that branch.
# The other versions don't have application benchmarks -- Figure 2 in the paper.
git checkout eurosys22/query-path-opt

for fs in "${FILE_SYSTEMS[@]}"; do
	# set target file system in fs-info.sh
	sed -i "s/^allfs=.*/allfs=(${fs})/g" fs-info.sh

	# run benchmarks
	sudo ./collect-all-fs.sh

	# process data
	./postprocess.sh 2>&- | grep -v '^[0-9]' | sed -E 's/[[:space:]]+/,/g' > "$ARTIFACT_DIR/results/$fs-$TIME.csv"
done

# restore target filesystem to BetrFS
sed -i "s/^allfs=.*/allfs=(ftfs)/g" fs-info.sh

echo -e "\n[BetrFS] Done collecting data for other file systems\n"
