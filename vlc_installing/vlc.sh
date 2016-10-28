#!/bin/bash
echo "Getting in to the yum.repos.d directory to check if there is already a repo for vlc multimedia player......."
cd /etc/yum.repos.d/
echo "downloading the repo for vlc player........"
wget http://pkgrepo.linuxtech.net/el6/release/linuxtech.repo
sleep 5
echo " checking the list of vlc........."
yum list *vlc*
echo "installing vlc multimedia player .......keep calm..."
yum -y install vlc
echo " vlc has been installed.........uhhhh hooooo..!!! enjoy....."


