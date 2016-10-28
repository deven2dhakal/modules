#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@conversantmedia.com>
# Date: Wed Oct  1 17:56:13 UTC 2014
# Purpose: To ease configuring Dell hardware via OMSA utilities
# Updated 20141106 by zbukhari
# * Found a bug which didn't correctly list available drives for mkr0sdX and mkrXsdY

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/root/bin:.

function _cfgmaxpower {
	# Use Performance Optimized Power settings
	omconfig $C_OR_M_ARG pwrmanagement config=profile setting=maxperformance
	omconfig $C_OR_M_ARG biossetup attribute=SysProfile setting=PerfOptimized

	# 12G
	# Switch to custom to allow for disabling of MonitorMwait (12G)
	omconfig $C_OR_M_ARG biossetup attribute=SysProfile setting=Custom
	omconfig $C_OR_M_ARG biossetup attribute=MonitorMwait setting=Disabled

	# omconfig $C_OR_M_ARG pwrmanagement config=profile setting=custom
}

# Updated per SYSENG-694
function _enableht {
	omconfig $C_OR_M_ARG biossetup attribute=cpuht setting=enabled
	omconfig $C_OR_M_ARG biossetup attribute=LogicalProc setting=Enabled
}

function _cfghardcpu {
	# Only virtualization servers benefit from this.
	omconfig $C_OR_M_ARG biossetup attribute=cpuvt setting=disabled
	omconfig $C_OR_M_ARG biossetup attribute=ProcVirtualization setting=Disabled

	# Disable Hyper-Threading / Logical processors
	omconfig $C_OR_M_ARG biossetup attribute=cpuht setting=disabled
	omconfig $C_OR_M_ARG biossetup attribute=LogicalProc setting=Disabled

	# Enable turbo mode
	omconfig $C_OR_M_ARG biossetup attribute=cputurbomode setting=enabled
	omconfig $C_OR_M_ARG biossetup attribute=ProcTurboMode setting=Enabled

	# Adjust no direct execute bit check
	# omconfig $C_OR_M_ARG biossetup attribute=cpuxdsupport setting=disabled

	# Enable all cores
	omconfig $C_OR_M_ARG biossetup attribute=cpucore setting=all
	omconfig $C_OR_M_ARG biossetup attribute=ProcCores setting=All

	# Disable C1E state
	omconfig $C_OR_M_ARG biossetup attribute=cpuc1e setting=disabled
	omconfig $C_OR_M_ARG biossetup attribute=ProcC1E setting=Disabled

	# Disable CPU C-states via omconfig + kernel
	omconfig $C_OR_M_ARG biossetup attribute=cstates setting=disabled
	omconfig $C_OR_M_ARG biossetup attribute=ProcCStates setting=Disabled
}

function _cfgserial {
	# Remote Access configuration
	omconfig $C_OR_M_ARG remoteaccess config=nic enableipmi=true
	omconfig $C_OR_M_ARG remoteaccess config=serialoverlan enable=true baudrate=115200 privilegelevel=operator

	# Chassis External Serial Connector
	if [ x"$CHASSIS_TYPE" != "xMulti-system" ]; then
		omconfig $C_OR_M_ARG biossetup attribute=extserial setting=serialdev1
	fi

	# Set serial port address
	omconfig $C_OR_M_ARG biossetup attribute=serialportaddr setting=${SPA}

	# Serial Communications
	omconfig $C_OR_M_ARG biossetup attribute=serialcom setting=${SERCOMM}

	# Console Redirection After Boot
	omconfig $C_OR_M_ARG biossetup attribute=crab setting=enabled

	# Console Redirection Failsafe BAUD Rate
	omconfig $C_OR_M_ARG biossetup attribute=fbr setting=115200

	# 12G argument but may as well try for it.
	omconfig $C_OR_M_ARG biossetup attribute=ConTermType setting=Vt100Vt220

	# 12G hardware - the old flags still work
	# omconfig $C_OR_M_ARG biossetup attribute=ExtSerialConnector setting=Serial1
	# omconfig $C_OR_M_ARG biossetup attribute=SerialPortAddress setting=Serial1Com1Serial2Com2
	# omconfig $C_OR_M_ARG biossetup attribute=SerialComm setting=OnConRedirCom2
	# omconfig $C_OR_M_ARG biossetup attribute=RedirAfterBoot setting=Enabled
	# omconfig $C_OR_M_ARG biossetup attribute=FailSafeBaud setting=115200
}

function _mkr0sdX {
	case "$MODEL" in
		"PowerEdge R510")
			SCSI_ENCLOSURE=0
			;;
		"PowerEdge R720xd")
			SCSI_ENCLOSURE=1
			;;
		*)
			echo This script is not built to handle the server type you are on
			exit 1
	esac

	declare -a DRIVE_ID_2_LETTER

	DRIVE_ID_2_LETTER[0]=b
	DRIVE_ID_2_LETTER[1]=c
	DRIVE_ID_2_LETTER[2]=d
	DRIVE_ID_2_LETTER[3]=e
	DRIVE_ID_2_LETTER[4]=f
	DRIVE_ID_2_LETTER[5]=g
	DRIVE_ID_2_LETTER[6]=h
	DRIVE_ID_2_LETTER[7]=i
	DRIVE_ID_2_LETTER[8]=j
	DRIVE_ID_2_LETTER[9]=k
	DRIVE_ID_2_LETTER[10]=l
	DRIVE_ID_2_LETTER[11]=m

	# Configure available drive(s)
	for x in $(omreport storage pdisk controller=0 | egrep '^(ID|State)\s+:\s+' | tac | sed -n '/Ready/,+1p' | fgrep -v State | awk '{print $3}')
	do
		echo Valid drive: $x
		ID=$(echo $x | cut -f3 -d:)
		omconfig storage controller action=createvdisk controller=0 raid=r0 size=max pdisk=0:${SCSI_ENCLOSURE}:${ID} readpolicy=ara writepolicy=fwb name=r0sd${DRIVE_ID_2_LETTER[${ID}]}
	done
}

function _mkrXsdY {
	for x in $(omreport storage pdisk controller=0 | egrep '^(ID|State)\s+:\s+' | tac | sed -n '/Ready/,+1p' | fgrep -v State | awk '{print $3}')
	do
		echo Valid drive: $x

		if [ "x${PDISK}" = "x" ]; then
			PDISK=${x}
		else
			PDISK="${PDISK},${x}"
		fi
	done

	omconfig storage controller action=createvdisk controller=0 raid=${1} size=max pdisk=${PDISK} stripesize=1mb readpolicy=ara writepolicy=fwb

	echo You may want to name this RAID array something descriptive.
}

function _identify {
	echo Flashing server identification LED for 5 minutes
	omconfig $C_OR_M_ARG leds led=identify flash=on
}

function _identify_disk {
	echo Flashing pdisk ${3} on controller ${2}
	omconfig storage pdisk action=blink controller=${2} pdisk=${3}
}

function _disablemobopxe {
	echo "Disabling PXE for on-board NICs. Don't worry about errors."
	omconfig $C_OR_M_ARG biossetup attribute=dualnic setting=on

	for x in 1 2 3 4
	do
		omconfig $C_OR_M_ARG biossetup attribute=IntNic${x}Port1BootProto setting=None
		omconfig $C_OR_M_ARG biossetup attribute=nic${x} setting=enabledonly
	done
}

### BEGIN ###

MAKE=$(dmidecode -s system-manufacturer)
MODEL=$(dmidecode -s system-product-name)
SN=$(dmidecode -s system-serial-number)
CHASSIS_TYPE=$(dmidecode -s chassis-type)

if [ x"$MAKE" = "xDell Inc." ]; then
	if [ x"$CHASSIS_TYPE" = "xMulti-system" ]; then
		C_OR_M_ARG="mainsystem"
		SOLTTY=ttyS0
		SERCOMM=com1
		SPA=com1
	else
		C_OR_M_ARG="chassis"
		SOLTTY=ttyS1
		SERCOMM=com2
		SPA=default
	fi
else
	echo Only Dell hardware is supported.
	exit 1
fi

case "$1" in
	enableht)
		_enableht
		;;

	cfghardcpu)
		_cfghardcpu
		;;

	mkr0sdX)
		_mkr0sdX
		;;

	mkrXsdY)
		case "$2" in
			r5|r6|r10|r50|r60)
				_mkrXsdY $2
			;;

			*)
				echo "Usage: $0 mkrXsdY [r5|r6|r10|r50|r60]"
				;;
		esac
		;;

	cfgserial)
		_cfgserial
		;;

	cfgmaxpower)
		_cfgmaxpower
		;;

	identify)
		_identify
		;;

	identify_disk)
		if [ "x$3" = "x" ]; then
			echo "Usage: $0 identify_disk CONTROLLER_ID PDISK_ID"
			exit 1
		fi
		_identify_disk $2 $3
		;;

	disablemobopxe)
		_disablemobopxe
		;;

	*)
		cat <<HEREDOC
Usage: $0 OPTION ARG(S)

enableht:       Enable HT (i.e. Hyper-Threading).  You probably want to run
                cfghardcpu first.
cfghardcpu:     Disable VT-x, disable Hyper-Threading, disable C-States/C1E,
                enable all cores, enable turbo mode.
mkr0sdX:        Create single disk RAID-0 arrays using available drives.
mkrXsdY:        Create a RAID 5, 6, 10, 50, or 60 array using available drives.
                Takes an extra argument for RAID-level (e.g. $0 mkrXsdY r5).
cfgserial:      Configure serial console. Currently only for Serial-over-LAN.
cfgmaxpower:    Set the power management to maximum performance and disable
                Monitor/Mwait for 12G.
identify:       Flashes the server identification LED for 5 minutes.
identify_disk:  Flashes the disks identification LED for 5 minutes. Requires
                controller and pdisk ID (e.g. $0 0 0:1:3)
disablemobopxe: Disables on-board PXE. Useful for 10G base network servers.
HEREDOC
		exit 1
		;;
esac

echo Please be aware that most of these options will require a reboot.
