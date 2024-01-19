#!/bin/bash
sudo dhclient
sudo rpm -Uvhy https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
sudo yum update -y
sudo yum install -y vim expect epel-release.noarch wget htop curlftpfs 
sudo yum -y clean all
sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="no"
IPADDR=192.168.1.211
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=1.1.1.1
EOF
sudo echo "zabbix_agent01" > /etc/hostname 	
sudo systemctl start firewalld && sudo systemctl enable firewalld
sudo /etc/init.d/network restart
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
###CONFIG AGENT
sudo yum -y install zabbix-agent.x86_64
sudo sed -i 's/^Server=.*/Server=192.168.1.210/g' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/^ServerActive=.*/Server=192.168.1.210/g' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/^Hostname=.*/Hostname=zabbix_agent01/g' /etc/zabbix/zabbix_agentd.conf
sudo firewall-cmd --add-port=10050/tcp --permanent && sudo firewall-cmd --reload
sudo systemctl enable zabbix-agent && sudo systemctl start zabbix-agent
sudo reboot