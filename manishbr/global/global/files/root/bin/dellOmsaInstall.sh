#!/bin/bash

# Programmer: Zahid Bukhari <zbukhari@dotomi.com>
# Date: Tue May  7 09:16:32 UTC 2013
# Purpose: To configure DRAC networking

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin

# host linux.dell.com 2>&1 > /dev/null
# host linux.dell.com 2>&1 > /dev/null
# host linux.dell.com 2>&1 > /dev/null

case $HOSTNAME in
	*sjc*)
		DC=sjc
		;;
	*iad*)
		DC=iad
		;;
	*ams*)
		DC=ams
		;;
	*)
		DC=ord
		;;
esac

yum clean all
srvadmin-services.sh stop
yum -y remove dell* firmware* libcmpiCppImpl0 libsmbios libsmbios* libwsman* openwsman-* python-smbios smbios-utils-* srvadmin-* OpenIPMI OpenIPMI-libs
curl -s http://${dc}-dellomsa.dc.dotomi.net/latest/bootstrap.cgi | bash
# curl -s http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash
# curl -s http://linux.dell.com/repo/community/bootstrap.cgi | bash
yum clean all
yum -y install srvadmin-all OpenIPMI OpenIPMI-tools dell_ft_install
srvadmin-services.sh start
