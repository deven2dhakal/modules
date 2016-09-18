#!/bin/bash
#update fqdn with your hostname
fqdn=pmcentos.test
ip="$(ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
echo $ip
echo "setting the hostname as $fqdn in /etc/hosts file with ipaddress $ip ... "
echo "$ip       $fqdn" >> /etc/hosts
sleep 2
echo ""
printf "writing $fqdn as hostname in kernel..."
sleep 2
sysctl kernel.hostname=$fqdn
echo ""
sleep 2
service iptables stop & chkconfig iptables off & echo "firewall disabled at this point"
sleep 2
echo ""
echo "Finally getting repos..."
sleep 3
cd /opt
rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-10.noarch.rpm && echo "got puppet repos"
rpm -ivh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && echo "got epel repos"
sleep 5
echo ""
echo "Installing puppet-master..."
yum install -y puppet-server && echo "puppet master has been installed"
echo ""
sleep 3
echo ""
echo "Let's make sure to edit puppet.conf file"
sleep 2
cat /etc/puppet/puppet.conf
echo ""
echo ""
echo "Look into agent section, it's empty"
sleep 10
echo ""
echo "Let's fill that guy now"
sed -i "/\[agent\]/a server = $fqdn" /etc/puppet/puppet.conf &&
sed -i "/server = $fqdn/a pluginsync = true" /etc/puppet/puppet.conf &&
sed -i "/pluginsync = true/a report = true" /etc/puppet/puppet.conf &&
sleep 3
echo ""
cat /etc/puppet/puppet.conf
echo ""
echo "nice aye"
echo ""
echo "let's start the service now"
echo ""
service puppetmaster start && chkconfig puppetmaster on && echo "started"
echo ""
sleep 2
echo "Let's run puppet agent -t ...."
sleep 2
puppet agent -t && sleep 2
echo ""
echo "Let's run again"
puppet agent -t && sleep 2 && echo "done"
echo ""
puppet module install puppetlabs-stdlib && echo "stdlib installed"
sleep 2
yum install -y git && echo "git has been installed"
echo ""
sleep 2
yum install -y vim && echo "vim has been installed................................"
echo ""
echo ""
cp -R /vagrant/modules/add_admin/ /etc/puppet/modules/ && echo "add_admin module has been installed"
puppet apply /etc/puppet/modules/add_admin/tests/init.pp && echo "admin user created"
echo "later, aight!"
