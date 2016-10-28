#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Since we know puppet is running we'll use facts that are already set
IPADDR=$(facter ipaddress)
NETMASK=$(facter netmask)

# PREFIX will get set here
eval $(ipcalc -p ${IPADDR} ${NETMASK})

cd /etc/sysconfig/network-scripts
for x in ifcfg-*
do
	case $x in
		ifcfg-lo)
			;;
		*)
			sed -i 's/^HWADDR/#HWADDR/g; /^ONBOOT/d; /^IPADDR/d; /^PREFIX/d;' $x
			echo ONBOOT=no >> $x
			;;
	esac

	if [ $x = 'ifcfg-em1' ]; then 
		cat <<HEREDOC >> $x
IPADDR=${IPADDR}
PREFIX=${PREFIX}
HEREDOC
		sed -i 's/^ONBOOT=no/ONBOOT=yes/g' $x
	fi
done
