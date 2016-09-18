#!/bin/bash
#update fqdn with your hostname

#Jenkins will be launched as a daemon on startup. See /etc/init.d/jenkins for more details.
#The 'jenkins' user is created to run this service. If you change this to a different user via the config file, you must change the owner of /var/log/jenkins, /var/lib/jenkins, and /var/cache/jenkins.
#Log file will be placed in /var/log/jenkins/jenkins.log. Check this file if you are troubleshooting Jenkins.
#/etc/sysconfig/jenkins will capture configuration parameters for the launch.
#By default, Jenkins listen on port 8080. Access this port with your browser to start configuration.  Note that the built-in firewall may have to be opened to access this port from other computers.  (See http://www.cyberciti.biz/faq/disable-linux-firewall-under-centos-rhel-fedora/ for instructions how to disable the firewall permanently)
#A Jenkins RPM repository is added in /etc/yum.repos.d/jenkins.repo

fqdn=jenkins.test
sed -i 's/\(127.0.0.1 \)/\1 $fqdn/' /etc/hosts
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
yum install -y java && echo "java has been installed"
echo ""

sleep 2
echo "now going to install jenkings..........get comfortable but watch the process.."
sleep 2
echo ""
yum install -y wget && echo "installing wget so that we can wget the jenkins repo"
cd /opt
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo && echo "got jenkins repo"
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key && echo "got epel repos"
yum install -y jenkins && echo "jenkins has been installed"
sleep 5
echo ""
echo "restarting jenkins again................."
service jenkins start && echo "jenkins is restarted................"
echo ""
sleep 3
chkconfig jenkins on
echo ""

echo ""
echo "Disabling the firewall....................."

echo " now listing all firewall........"
service iptables stop
chkconfig iptables off
sleep 5
echo "checking java version..........."

sleep 5
echo "installing vim"
yum install -y vim && echo "vim has been installed..............."
sleep 5
echo "everything completed.. now.....later, aight!"
