#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Tue May  7 09:16:32 UTC 2013
# Purpose: Setting LCD panel to custom name
# Updated 20140723 by zbukhari
# * perl snippet only considers up to one dot - more dots cause problems. Added cut.
# * logic for $1 argument being set was corrected.  Missed a "!".

PATH=/bin:/sbin:/usr/bin:/usr/sbin

LCDNAME=$(echo $HOSTNAME | cut -f1 -d. | perl -ne 'chomp; /^dt(\D)\D+(\d+)(\D+)(\d+)([pdq])$/; $env = "" if $5 eq "p"; $env = "DEV" if $5 eq "d"; $env = "QA" if $5 eq "q"; print uc($3) . $env . "-" . $1 . $2 . "-" . $4 . "\n";')

if [ "x$1" != "x" ]; then
	LCDNAME="${1}"
elif [ "x$1" = "-h" -o "x$1" = "--help" ]; then
	echo Usage: $0 TEXT
	echo If TEXT is not given, the hostname will be altered and used for the LCD.
	exit
fi

echo Setting LCD to $LCDNAME
ipmitool delloem lcd set mode userdefined $LCDNAME
