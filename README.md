# BetrFS v0.6 Artifact for EuroSys 2022

The BetrFS team strongly believes that reproducibility of results is essential
to the research process. In pursuit of this ideal, we provide this document and
the accompanying scripts in this directory to help reproduce the results
presented in our EuroSys 2022 paper,
*BetrFS: A Compleat File System for Commodity SSDs*.
This paper presents BetrFS v0.6, and compares it to BetrFS v0.4 and several
commodity filesystems.

Specifically, the scripts provided in this repository are used to reproduce the
results in Table 3 and Figure 2 from the paper.

Roughly, the process for replication is as follows:

1. build and install the required kernel, and boot the new kernel
1. build the file system (if applicable)
1. run experiments
1. process data

This process is repeated for each file system. In addition to repeating this
process for each file system, we also run experiments for each individual
optimization documented in Table 3 of the paper. When the kernel can be reused,
we skip the corresponding step.

This repository only contains the helper scripts used to replicate results. The
actual BetrFS v0.6 code is located on various branches of
[oscarlab/betrfs](https://github.com/oscarlab/betrfs). The scripts in this
repository will clone oscarlab/betrfs, and checkout individual branches to
perform experiments. Refer to the top-level
[README.md file](https://github.com/oscarlab/betrfs/tree/eurosys22/query-path-opt)
on any of the `eurosys22/*` branches for a description of the layout the BetrFS
codebase.


## Warnings

- Reproducing our results takes a *very* long time. On our machines, more than
  22 hours!
- The SSD on which the experiments run will be formatted. All data will be
  **LOST** on this disk.
- SSDs degrade with normal use. Since these experiments exercise the SSD more
  than normal use, the lifespan of your SSD may decrease.
- **DATA LOSS** is possible on the root partition. Backup your machine. We
  recommend using a burner machine specifically for experiments.
- Up to three new kernels will be installed on your machine. The boot kernel
  will be changed.
- The dovecot mail server daemon will be built and installed.
- New user accounts will be created for the dovecot daemon.
- The default gcc and g++ version will be changed.


## System Requirements

The following hardware and software is required:
- A bare-metal x86\_64 machine with:
  - the stock version of Ubuntu 18.04.6
  - at least 250 GB of disk space in the root partition
- A commodity SATA SSD with at least 250 GB capacity separate from the root
  partition disk. This is the disk experiments will run on.

Our machine specs (from the paper):

> All experiments were conducted on a PowerEdge T130 with a 4-core 3.00 GHz
> Intel Xeon E3-1220 v6 CPU, and 32 GB RAM. The system runs 64-bit Ubuntu
> 18.04.6 with Linux kernel version 4.19.99 when we test BetrFS variants and
> version 5.9.15 for other file systems, in order to give the competition
> the advantage of any recent advances. We boot with the root file system on a
> 500 GB TOSHIBA DT01ACA0 HDD. The SSD under test is a 250 GB Samsung EVO 860
> SSD with a 512-byte page size and 12 GB write cache; we measure a peak raw
> sequential bandwidth at 567 MB/s for reads. For writes, the peak bandwidth is
> 502 MB/s when the data size is smaller than 12 GB and drops to 392 MB/s when
> the data size is larger than 12 GB, which we attribute to device-internal
> operations.

The Ubuntu and Linux kernel versions described in this document are the only
versions supported.

Estimated run times are provided in each section below. The run times were
measured on the machine described above. Run times will vary based on system
configuration. For example, a machine with more CPU cores will allow build
steps to finish sooner.

As with any systems experiment, you should avoid running other programs while
running the experiment. This ensures no external factors affect the experiment,
and introduce noise in the data collected.

While running benchmarks should take the bulk of the time, BetrFS v0.4,
BetrFS v0.6, and the remaining file systems use different kernels, so we must
build and install those kernels as well. In particular,

- BetrFS v0.4: stock Linux v4.19.99
- BetrFS v0.6: *patched* Linux v4.19.99
- All other file systems: stock Linux v5.9.15

We provide scripts to easily build the kernel.


## Tips

Many of the scripts we use have very long runtimes, so we _strongly_ recommend
running commands in a terminal emulator (eg. tmux or screen). This will allow
you to run a script in a "session", detach, and return after the estimated
runtime.

While root permissions are not strictly required for entire scripts, we
recommend running as root since some scripts may ask for your password in the
middle of execution. If you detach from a terminal session, and a password
prompt appears, the script will pause execution until you re-attach, and enter
the password.


## Install Dependencies

This step takes 60 minutes, and only needs to be performed once on a given
system.

To build the kernel, BetrFS v0.4, BetrFS v0.6, and ZFS, several dependencies
are required. These dependencies are enumerated and documented in
`install-deps.sh`. Simply run this script to install dependencies. This script
will also build and install the dovecot mailserver and filebench, and clone the
betrfs code repo to `betrfs/`.

```shell
sudo ./install-deps.sh
```


## Configuration

`install-deps.sh` sets some of the following configuration parameters to
reasonable values, but it is wise to double-check if they are correct. You
still need to manually set `sb_dev`.

- `sb_dev`: This is the block device under `/dev` that corresponds to the SSD
  on which the experiments will be run. For example, on our machines,
  `sb_dev=/dev/sdc`. `sb_dev` is **NOT** the device on which your root
  partition resides. The contents of this device will be LOST.
- `dummy_dev`: Any free loop device. Defaults to `/dev/loop0`. If loop0 is
  already in use or you're unsure whether it's being used, try running
  `losetup -f` to find the next free loop device.
- `CUR_MNTPNT`: The absolute path of the directory that contains the BetrFS
  code repo. For our purposes, CUR\_MNTPNT will be the path to this artifact
  repo.
  - for example, if the repo is
  `/home/betrfs/betrfs-eurosys22-artifact/betrfs`, then the
  `CUR_MNTPT` variable should be set to
  `/home/betrfs/betrfs-eurosys22-artifact`.

Go ahead and modify these parameters in `betrfs/benchmarks/fs-info.sh`. In the
remainder of this document, we assume they are correctly set. Do **NOT** commit
these parameters: our helper scripts will switch between branches. If you
commit these configuration changes, they will be lost when checking out the
other branches.

The branches have been carefully constructed such that there are no changes to
`fs-info.sh` between branches. This ensures the modified `fs-info.sh` file
doesn't cause any issues when switching between branches.


## Experiments

Now, we are ready to run experiments. We will follow this general pattern:

```shell
# install new kernel
sudo ./pre-*.sh
sudo reboot

# run benchmarks
sudo ./eval-*.sh
```

The `pre-*.sh` scripts install the required kernel, and any other dependencies.
The machine must be rebooted after running this script so the required kernel is
booted, and used in the next step.

The `eval-*.sh` scripts run the actual benchmarks. Results of the experiments
are placed in CSV files in the `results/` directory. These scripts will also
check whether the correct kernel is booted before starting experiments.


### BetrFS v0.4 Experiments

This section describes how to collect data for BetrFS v0.4.

We begin by building and installing the stock v4.19.99 Linux kernel, and then
setting it as the boot kernel. We provide a wrapper script for convenience.
Then, simply reboot to the newly installed kernel. This step takes 30 minutes.

```shell
sudo ./pre-betrfs-v0.4.sh
sudo reboot
```

After rebooting, we are ready to build BetrFS v0.4 and run benchmarks. As a
reminder, make sure the parameters are correctly set in
`betrfs/benchmarks/fs-info.sh`. This step takes 3 hours and 10 minutes.

```shell
sudo ./eval-betrfs-v0.4.sh
```

If all went well, you should see

```
[BetrFS] Done collecting data for BetrFS v0.4
```

If something went wrong, reboot the machine, and try to run
`eval-betrfs-v0.4.sh` again.

The results of the experiments are placed in CSV files in `results/`.


### Manual experiments for BetrFS v0.4

BetrFS v0.4 non-deterministically fails some benchmarks:

- IMAP
- git: clone, and diff
- filebench: OLTP, webserver, and webproxy

If you are not concerned with reproducing these results, then skip to the
[next section](#betrfs-v06-experiments).

Since these benchmarks are finicky, they need to be run manually. You will also
need to write down the results of these benchmarks. After the estimated run
time, if the benchmark appears to be stuck, check `dmesg` for errors.

```shell
dmesg | egrep 'BUG|INFO: task .* blocked for more than [0-9]+ seconds.'
```

If an error is indicated, force reboot the machine, and try running the
experiment again.

Begin by selecting the correct branch, and building the BetrFS v0.4 code. The
eval-betrfs-v0.4.sh script conveniently does this when using a command-line
parameter:

```shell
sudo ./eval-betrfs-v0.4.sh --manual
```


#### IMAP experiment

The IMAP experiment should be run three times. To run it once:

```shell
cd betrfs/benchmarks/macro/mailserver/imap-test/
# takes 6 minutes
sudo ./run-test.sh ftfs
cd -
```

The script should output the time taken to complete the experiment. Note this
latency.

```
IMAP Punish: 8 threads, 10000 operations, 10 mailboxes, 50 % writes
This experiment took 328.869062 seconds
imap-publish, 328.869062
```

#### git experiments

The git experiments should be run five times. To run them once:

```shell
cd betrfs/benchmarks/application/git/
# takes 1 minute, possibly longer the first time
sudo ./run-git-clone.sh
# takes 1 minute
sudo ./run-git-diff.sh
cd -
```

The output of each script includes the output of `time(1)`. Note the real time.

```
real 21.76
user 15.12
sys 3.90
```

#### filebench experiments

As noted in the paper, filebench's fileserver workload does not work on BetrFS
v0.4.

The filebench experiments should be run five times. To run them once:

```shell
cd betrfs/benchmarks/macro/filebench/
# takes 1 minute 30 sec
sudo ./run-test.sh oltp ftfs
# takes 1 minute 30 sec
sudo ./run-test.sh webproxy ftfs
# takes 1 minute 30 sec
sudo ./run-test.sh webserver ftfs
cd 
```

The output of each script includes an `IO Summary` line. Note the ops/s metric.

```
61.569: IO Summary: 1444843 ops 23942.615 ops/s 12110/11712 rd/wr  46.6mb/s   0.0ms/op
```


### BetrFS v0.6 Experiments

This section describes how to run experiments on BetrFS v0.6, and its
individual optimizations. This empirically measures the core contributions of
our paper.

The process to run experiments on BetrFS v0.6 and its individual optimizations
is very similar to that of BetrFS v0.4. However, this time we collect data from
seven different branches to represent the individual optimizations BetrFS v0.6
presents. So, this time, collecting data takes longer.

```shell
# install new kernel
# takes 30 minutes
sudo ./pre-betrfs-v0.6.sh
sudo reboot

# run benchmarks
# takes 7 hr 30 min
sudo ./eval-betrfs-v0.6.sh
```

Seven additional CSV files should now be present in `results/`.


### Other File System Experiments

Finally, we run experiments on each of the competitor file systems.

```shell
# install new kernel
# takes 60 minutes
sudo ./pre-other.sh
sudo reboot

# run benchmarks
# takes 7 hr 40 min
sudo ./eval-other.sh
```

`pre-other.sh` takes longer to run than the other `pre-*.sh` scripts since
`pre-other.sh` also builds and installs ZFS as a kernel built-in.

Five additional CSV files corresponding to each of the competitor file systems
should now be present in `results/`.


### Results

This completes the experiments. The `results/` directory should now contain 13
CSV files corresponding to the 13 rows of Table 3. The data corresponding to
Figure 2 is also in these CSV files.

It should be noted that the data collected for the IMAP benchmark has units of
seconds. However, the paper reports the IMAP results in op/s in Figure 2(d).
The IMAP benchmark uses 8 threads, and each thread performs 10,000 operations.
So, the latency can be converted to throughput by,

```
throughput = 8 * 10,000 / latency
```


### Repeating experiments

If you want to _repeat_ one of the above experiments, running the `pre-*.sh` is
not recommended since the kernel has already been built, and installed. Instead
use `change-boot-kernel.sh`:

```shell
# set boot kernel
sudo ./change-boot-kernel.sh $KERNEL
sudo reboot

# run benchmarks
sudo ./eval-*.sh
```

Here, `$KERNEL` refers to the name of the required kernel for the corresponding
experiment. The mapping is,

```
betrfs v0.4: 4.19.99
betrfs v0.6: 4.19.99-betrfs-v0.6
other:       5.9.15
```


## Troubleshooting

You may find that the experiment appears to be stuck. To determine whether this
is the case, begin by checking dmesg for a kernel BUG.

```shell
dmesg | grep BUG
```

If a BUG occurred, terminate the experiment, and reboot the machine. You may
need to force reboot.

If a BUG didn't occur, it's possible the experiment is simply still running,
and taking longer than expected. Try to use `htop(1)` and/or `iotop(8)` to
check whether the CPU or disk is being utilized. If system resources are being
utilized, then wait a bit longer for the experiment to finish. Otherwise,
reboot the machine.

For further questions, please open an issue in this repository.

[![DOI](https://zenodo.org/badge/453248864.svg)](https://zenodo.org/badge/latestdoi/453248864)

