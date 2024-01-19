#!/bin/bash
sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="no"
IPADDR=192.168.1.209
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=1.1.1.1
EOF
#sudo /etc/init.d/network restart
sudo echo "Amendoin" > /etc/hostname 	
sudo setenforce 0
###BINARIOS NECESSARIOS
sudo yum update -y
sudo yum install -y epel-release wget perl iotop net-tools htop vim wget httpd
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql10-server postgresql10 postgresql-contrib 
###DEAMON CONFIG
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
sudo systemctl start postgresql-10.service && sudo systemctl enable postgresql-10.service
###CONFIG FILES
sudo su - postgres
sudo sed -i 's/ident/md5/g' /var/lib/pgsql/10/data/pg_hba.conf
###END
sudo systemctl enable firewalld && sudo systemctl start firewalld
sudo firewall-cmd --add-port={5432/tcp,5433/tcp} --permanent && sudo firewall-cmd --reload
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
sudo yum clean all -y