#!/bin/bash

# set up
set -eux
ARTIFACT_DIR=$PWD
TIME=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p results
if [[ "$(uname -r)" != "4.19.99" ]]; then
	echo "ERROR: correct kernel version is not running."
	exit 1
fi

# build BetrFS v0.4
cd betrfs
git clean -xfdq -e benchmarks
git checkout eurosys22/betrfs-v4-linux4.19.99
./build.sh -b

# check if we only want to build the code. This is for manually testing the
# benchmarks that BetrFS v0.4 non-determinisitically fails. Refer to README.md
# for details.
if [[ $# -ne 0 ]]; then
	if [[ $# -eq 1 && $1 = "--manual" ]]; then
		echo -e "\n[BetrFS] Prepared BetrFS v0.4 for manual testing.\n"
		exit 0
	else
		echo "ERROR: Usage: $0 [--manual]"
		exit 1
	fi
fi

# run benchmarks
cd benchmarks/
sudo ./collect-all-fs.sh

# process data
BRANCH_NAME=$(basename $(git rev-parse --abbrev-ref HEAD))
./postprocess.sh 2>&- | grep -v '^[0-9]' | sed -E 's/[[:space:]]+/,/g' > "$ARTIFACT_DIR/results/$BRANCH_NAME-$TIME.csv"

echo -e "\n[BetrFS] Done collecting data for BetrFS v0.4\n"
