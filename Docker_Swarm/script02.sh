#!/bin/bash
sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="no"
IPADDR=192.168.1.212
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=1.1.1.1
EOF
sudo hostnamectl set-hostname robot02						
sudo yum update -y && yum install epel-release
sudo curl -fsSL https://get.docker.com | bash && sudo usermod -aG docker vagrant            
yum install -y glusterfs-client wget perl iotop net-tools htop git policycoreutils selinux-utils selinux-basics && \
sudo systemctl start firewalld && systemctl enable firewalld docker
sudo firewall-cmd --permanent --zone=public --add-service={docker,sshd} && firewall-cmd --reload
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux		