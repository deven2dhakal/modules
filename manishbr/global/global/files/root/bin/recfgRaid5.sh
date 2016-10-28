#!/bin/sh

for x in {1..12}
do
	omconfig storage vdisk action=deletevdisk vdisk=${x} controller=0
	if [ "x${PDISK}" = "x" ]; then
		PDISK=0:1:$((x - 1))
	else
		PDISK="${PDISK},0:1:$((x - 1))"
	fi
done

omconfig storage controller action=createvdisk controller=0 raid=r5 size=max pdisk=${PDISK} stripesize=1mb readpolicy=ara writepolicy=fwb name=r5sdb

parted -s -- /dev/sdb mklabel gpt
parted -s -- /dev/sdb mkpart primary ext2 1 100%
mkfs.xfs -f -l size=67108864 -L /dotomi/gbu2 /dev/sdb1
echo "LABEL=/dotomi/gbu2 /dotomi/gbu2 xfs rw,noatime,nodiratime,logbufs=8,nobarrier,inode64 1 2" >> /etc/fstab
mkdir -p /dotomi/gbu2
mount -a
