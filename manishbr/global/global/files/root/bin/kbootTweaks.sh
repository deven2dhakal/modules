#!/bin/sh

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Wed May 15 19:14:19 UTC 2013
# Purpose: To disable C-states
# Updated 20141002 by zbukhari
# - Creating various other kernel boot parameter options
# - Added pre-load variables and checks
# Updated 20150430 by zbukhari
# - Using grubby and created enabled disable options
# - Adding in a lot more checks and balances specifically for ttySx

PATH=/bin:/sbin:/usr/bin:/usr/sbin

function _serialconsole {
	# sed -i "/^\tkernel/ { /\<console=tty\>/! { s/$/ console=tty0 console=${SOLTTY},115200n8/; } }" ${GRUB_CONF}
	grubby --update-kernel=ALL --${ARGS}="console=${SOLTTY},115200n8 console=tty0 console=tty"

	# securetty
	grep -q "^${SOLTTY}" /etc/securetty
	if [ $? -ne 0 ]; then
		echo $SOLTTY >> /etc/securetty
	fi

	# Specific to RHEL version
	case $KERNEL_VERSION in
		# CentOS 5
		2.6.18-*)
			# inittab
			if [ "x$ARGS" = "xargs" ]; then

				# inittab
				grep -q "^S$(echo $SOLTTY | cut -c 5):12345:respawn:/sbin/agetty /dev/${SOLTTY} 115200 vt100-nav$" /etc/inittab
				if [ $? -ne 0 ]; then
					sed -i "/^S$(echo $SOLTTY | cut -c 5):/d; $ a\S$(echo $SOLTTY | cut -c 5):12345:respawn:/sbin/agetty /dev/${SOLTTY} 115200 vt100-nav" /etc/inittab
				fi
			else
				# Removal
				sed -i "/^S$(echo $SOLTTY | cut -c 5):/d" /etc/inittab
			fi

			# Reload init
			telinit q
			;;

		# CentOS 6
		2.6.32-*)
			if [ "x$ARGS" = "xargs" ]; then
				# Test to see if TTY is in use and if not - start serial service
				ps auxww | fgrep ${SOLTTY} 2>&1 > /dev/null
				if [ $? -ne 0 ]; then
					start serial DEV=${SOLTTY} SPEED=115200 vt100-nav
				fi
				# securetty
				grep -q "^${SOLTTY}" /etc/securetty
				if [ $? -ne 0 ]; then
					echo $SOLTTY >> /etc/securetty
				fi
			else
				stop serial DEV=${SOLTTY} SPEED=115200 vt100-nav
				sed -i "/^${SOLTTY}$/d" /etc/securetty
			fi
			;;

		# CentOS 7
		3.10.0-*)
			if [ "x$ARGS" = "xargs" ]; then
				systemctl status serial-getty@${SOLTTY} 2>&1 > /dev/null
				if [ $? -ne 0 ]; then
					systemctl start serial-getty@${SOLTTY}
				fi
			else
				systemctl stop serial-getty@${SOLTTY}
			fi
			;;
	esac

	echo This will most likely require a reboot.
}

function _cstates {
	# sed -i '/^\tkernel/ { /\<idle=poll\>/! { s/$/ intel_idle.max_cstate=0 processor.max_cstate=0 idle=poll/; } }' ${GRUB_CONF}
	grubby --update-kernel=ALL --${ARGS}="intel_idle.max_cstate=0"
	grubby --update-kernel=ALL --${ARGS}="processor.max_cstate=0"
	grubby --update-kernel=ALL --${ARGS}="idle=poll"
	echo Requires reboot
}

function _printk {
	if [ "x$ARGS" = "xargs" ]; then
		# sed -i '/^\tkernel/ { /\<time=1\>/! { s/$/ time=1/; } }' ${GRUB_CONF}
		grubby --update-kernel=ALL --${ARGS}="${PRINTK_PARAM}"
		echo 1 > ${PRINTK_FILE}
	else
		grubby --update-kernel=ALL --${ARGS}="${PRINTK_PARAM}"
		echo 0 > ${PRINTK_FILE}
	fi
}

### BEGIN ###
MAKE=$(dmidecode -s system-manufacturer | grep -v '^#')
MODEL=$(dmidecode -s system-product-name | grep -v '^#')
SN=$(dmidecode -s system-serial-number | grep -v '^#')
CHASSIS_TYPE=$(dmidecode -s chassis-type | grep -v '^#')

if [ x"$MAKE" = "xDell Inc." ]; then
	if [ x"$CHASSIS_TYPE" = "xMulti-system" ]; then
		C_OR_M_ARG="mainsystem"
		SOLTTY=ttyS0
	else
		SOLTTY=ttyS1
	fi
else
	echo Only Dell hardware is supported.
	exit 1
fi

KERNEL_VERSION=$(uname -r)

### Pre-set certain parameters for ease
case $KERNEL_VERSION in
	# CentOS 5
	2.6.18-*)
		PRINTK_PARAM="time=1"
		PRINTK_FILE=/sys/module/printk/parameters/printk_time
		;;
	2.6.32-*|3.10.0-*)
		PRINTK_PARAM="printk.time=1"
		PRINTK_FILE=/sys/module/printk/parameters/time
		;;
	*)
		echo WARNING: Some parameters may not be set for this kernel version.
		;;
esac

case "$1" in
	enable)
		ARGS=args
		;;
	disable)
		ARGS=remove-args
		;;
	*)
		echo "Usage: $0 [enable|disable] [printk|cstates|serialconsole]"
		exit 1
		;;
esac

case "$2" in
	printk|cstates|serialconsole)
		_${2} ${1}
		;;
	*)
		echo "Usage: $0 [enable|disable] [printk|cstates|serialconsole]"
		exit 1
		;;
esac
