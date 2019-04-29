#!/bin/bash

DEVICE="/dev/xvdb"
MOUNT_POINT="/prometheus"
FS_TYPE="xfs"

mkdir $MOUNT_POINT
# device is unformated, therefore format, mount & add to fstab.
if [ "1" -eq "$(file -s ${DEVICE} | grep -c data)" ]; then
  mkfs -t $FS_TYPE $DEVICE
  mount $DEVICE $MOUNT_POINT
  UUID=$(lsblk -o UUID $DEVICE | tail -1)
  # echo "UUID=c6ccbc2f-8abd-4de7-9d29-24316df91cf5       /prometheus_data        xfs     defaults,nofail 0       2" >> /etc/fstab
  echo "UUID=${UUID}    ${MOUNT_POINT}    ${FS_TYPE}    defaults,nofail    0 2" >> /etc/fstab
  # Prometheus runs with the same UID/GUID as nfsnobody.
  # Therefore needs those write permissions.
  chgrp nfsnobody $MOUNT_POINT
  chmod g+sw $MOUNT_POINT
fi

exit 0
