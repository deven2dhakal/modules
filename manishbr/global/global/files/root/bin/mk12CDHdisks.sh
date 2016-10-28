#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@conversantmedia.com>
# Date: Wed Nov  5 17:04:04 CST 2014
# Purpose: To stand up drives for CDH
# Updated 20141118 by zbukhari
# * Adjusted to handle mount permissions for mount point and root mount point.
# * Re-did LABEL= convention - it's non-standard but understandable.
# * Changed mount point to /hadoop/diskNN vs /cdh/dataNN.

PATH=/bin:/sbin:/usr/bin:/usr/sbin

# This creates the RAID-0 single disk arrays
/root/bin/omsaTweaks.sh mkr0sdX

# Now we work with the drives
i=1
os_disk=$(mount | grep boot | awk '{print $1}' | sed 's/1$//g')
for DRIVE in sd{a..z} # changed to a - z just to support more drives in the future
do

  # Basically if the drive doesn't exist, don't try to force it to exist
  if [ ! -e "/dev/${DRIVE}" ]; then
    i=$((i+1)) # we should keep track of this, so if we lose a drive, it'll be easier to fix automatically
    continue
  fi

  if [ "$DRIVE" == "${os_disk}" ]; then
    continue # no need to count here
  fi


  # Creating a separate log device would require some TLC
  # However it's a considerable performance option

  # Test to see if device has a partition
  file -s /dev/${DRIVE}1 | fgrep 'SGI XFS' 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    # no partition - we're going to make one cuz we kray-zee
    echo Creating /dev/${DRIVE}1 partition
    parted -a opt -s /dev/${DRIVE} -- \
    mklabel gpt \
    mkpart primary xfs 0% 100% 2>&1 | while read line; do echo "  [parted] > ${line}"; done

    echo Creating XFS file system on /dev/${DRIVE}1
    mkfs.xfs -f -L /hadoop${i} /dev/${DRIVE}1 2>&1 | while read line; do echo "  [mkfs.xfs] > ${line}"; done
  else
    echo /dev/${DRIVE}1 partition with XFS file system already present.
  fi

  # Test to see if we need to do adjust fstab
  egrep "\s+/hadoop/disk${i}\s+" /etc/fstab 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    echo Adding mount for CDH disk ${i} in /etc/fstab
    echo "# Cloudera Hadoop disk ${i}" >> /etc/fstab
    echo "LABEL=/hadoop${i} /hadoop/disk${i} xfs rw,noatime,nodiratime,nobarrier,inode64,nosuid,nodev,noquota,noattr2 1 2" >> /etc/fstab
  else
    echo LABEL=/hadoop${i} or /hadoop/disk${i} mount already present.
  fi

  test -d /hadoop/disk${i}
  if [ $? -ne 0 ]; then
    echo Creating mount point for Cloudera Hadoop disk ${i}
    mkdir -p /hadoop/disk${i}
    echo Changing ownership of mount point for Cloudera Hadoop disk ${i} to vchadoop
    chown vchadoop:vchadoop /hadoop/disk${i}
  fi

  egrep "\s+/hadoop/disk${i}\s+" /proc/mounts 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    echo Normalizing permissions for root of /hadoop/disk${i} mount to vchadoop.
    mount /hadoop/disk${i}
    chown vchadoop:vchadoop /hadoop/disk${i}
  else
    echo /hadoop/disk${i} is mounted. Will not normalize permissions of root mount point to vchadoop.
  fi

  i=$((i+1))
done
