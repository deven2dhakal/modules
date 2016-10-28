#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$HOME/bin:.

if [ -f "/sys/class/net/bonding_masters" ]; then
  echo This is already configured with a bond. Begrudgenly exiting
  exit
fi

if [ -f "/etc/sysconfig/network-scripts/ifcfg-bond0" ]; then
  echo This is already configured with a bond.  I unfriend you.
  exit
fi

if [ `whoami` != "root" ]; then
  echo "That's not how this works. That's not how any of this works (you need root)"
  exit
fi

# turn up all the eth/em interfaces
for i in `ls -1 /sys/class/net/ | egrep 'eth|em'`;
do
  INTS="$INTS $i"
  /sbin/ifup $i
done
sleep 5
for i in $INTS
do
  if [ `cat /sys/class/net/$i/carrier` -eq '1' ]
  then
    UPLINKS="$UPLINKS $i"
    IPADDR=`/usr/sbin/ip add show $i | awk '$1 == "inet" {print $2}'`
    if [ $IPADDR ]; then
      IP=`echo ${IPADDR} | sed 's/\/.*//'`
      MASK=`/usr/bin/ipcalc -m ${IPADDR}`
    fi
  fi
done
echo found $IP and $UPLINKS and $MASK
echo creating bond0 master

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
IPADDR=${IP}
$MASK
BONDING_OPTS="mode=802.3ad miimon=100 lacp_rate=1 xmit_hash_policy=layer2+3"
EOF

for IF in $UPLINKS
do
  echo Configuring ${IF} as a slave interface of bond0 on /etc/sysconfig/network-scripts/ifcfg-${IF}
  cp /etc/sysconfig/network-scripts/ifcfg-${IF} /etc/sysconfig/network-scripts/ifcfg-${IF}.prebond
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-${IF}
DEVICE=${IF}
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF
done

cat <<HEREDOC
For RHEL 7 based machines you will want to disable the NetworkManager.service
and ensure the network.service is enabled.  You probably want to be in a
console session.  The commands if interested are below:

systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl enable network.service
systemctl start network.service
systemctl restart network.service
HEREDOC
