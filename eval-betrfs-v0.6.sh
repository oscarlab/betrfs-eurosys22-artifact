#!/bin/bash

# set up
set -eux
ARTIFACT_DIR=$PWD
TIME=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p results
if [[ "$(uname -r)" != "4.19.99-betrfs-v0.6" ]]; then
	echo "ERROR: correct kernel version is not running."
	exit 1
fi

BRANCHES=(
	eurosys22/sfl-kernel-4.19.99
	eurosys22/range-kernel-4.19.99
	eurosys22/malloc-opts-kernel-4.19.99
	eurosys22/page-sharing
	eurosys22/dc-kernel-4.19.99
	eurosys22/cond-log-opt
	eurosys22/query-path-opt
)

cd betrfs

for branch in "${BRANCHES[@]}"; do
	git clean -xfdq -e benchmarks
	git checkout $branch
	# The -b flag is only present in some versions of build.sh. In any case, it
	# builds the release version by default.
	./build.sh

	# run benchmarks
	cd benchmarks/
	sudo ./collect-all-fs.sh

	# process data
	BRANCH_NAME=$(basename $branch)
	./postprocess.sh 2>&- | grep -v '^[0-9]' | sed -E 's/[[:space:]]+/,/g' > "$ARTIFACT_DIR/results/betrfs-v0.6-$BRANCH_NAME-$TIME.csv"
	cd -
done

echo -e "\n[BetrFS] Done collecting data for BetrFS v0.6\n"
