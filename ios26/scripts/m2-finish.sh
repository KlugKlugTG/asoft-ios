#!/bin/bash
# Finish the first root26 build (its sysroot step stopped on cp -a's ACLs), then apply root26-tweaks.py.
set -eu
A=${ASOFT26:?set ASOFT26 to the build folder as WSL sees it, e.g. /mnt/d/ios26}
S=$(cd "$(dirname "$0")" && pwd)
DISK=${1:-$A/root26.qcow2}
bash $S/root26-do.sh $DISK '
set -e
stage=$R/.sysroot-stage
if [ -d $stage ]; then
	rsync -rlptgo --ignore-existing $stage/ $R/
	rm -rf $stage
fi
ls -la $R/bin/bash $R/bin/sh $R/usr/lib/dyld $R/sbin/launchd
ls $R/System/Library/Caches/com.apple.dyld | head -3
ls -la $R/System/Cryptexes/ $R/private/preboot/Cryptexes/
python3 -I '"$S"'/root26-tweaks.py $R
df -h $R | tail -1'
NBD=${NBD:-/dev/nbd12}
# (a block device, in the installer's helper VM: as it is)
[ -b $DISK ] && NBD=$DISK || { qemu-nbd -f qcow2 -c $NBD $DISK; sleep 1; }
# the repair pass only (the -n verification read the whole volume again; the partition step's
# fsck repairs the copy before it is booted)
fsck.hfsplus -f -y $NBD | grep -v "Illegal name" | tail -4 || true
[ $NBD = $DISK ] || qemu-nbd -d $NBD > /dev/null
