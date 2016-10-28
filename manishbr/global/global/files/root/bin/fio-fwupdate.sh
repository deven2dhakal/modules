#!/bin/sh

PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

#Install the latest firmware
#FIRMWAREPATH="/usr/share/fio/firmware/"

FIOABIN=$(rpm -ql fio-firmware-fusion | grep '.fff')
FIOUPDATE=$(fio-status| grep -ow 'MINIMAL MODE')

if [ "$FIOUPDATE" = "MINIMAL MODE" ]; then
  fio-update-iodrive -q $FIOABIN
  echo Reboot required. Firmware has been updated
  sleep 5
 # echo Rebooting in five minutes. You can cancel a shutdown by executing shutdown -c
 # shutdown -r 15 Reboot required. Firmware has been updated.
  shutdown -r +5 "Rebooting in 5 minutes You can cancel a shutdown by executing shutdown -c"
fi
