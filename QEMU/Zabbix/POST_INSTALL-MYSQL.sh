#!/bin/bash
sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="no"
IPADDR=192.168.1.210
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=1.1.1.1
EOF
sudo echo "zabbix" > /etc/hostname 	
echo "192.168.1.210 zabbix.labary.local" >> /etc/hosts
sudo nmcli networking off && sudo nmcli networking on
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo systemctl start firewalld && sudo systemctl enable firewalld
sudo dnf update -y && sudo dnf install -y vim expect epel && sudo dnf -y clean all
###CONFIG MYSQL
sudo dnf install -y mysql-server && sudo dnf -y clean all
sudo systemctl enable mysqld && sudo systemctl start mysqld
      MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')
      MYSQL_ROOT_PASSWORD="q1w2e3r4t5y6u7i8"
      SECURE_MYSQL=$(expect -c "
      set timeout 10
      spawn mysql_secure_installation
      expect "Enter password for user root:"
      send "$MYSQL\r"
      expect "Change the password for root ?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect "New password:"
      send "$MYSQL_ROOT_PASSWORD\r"
      expect "Re-enter new password:"
      send "$MYSQL_ROOT_PASSWORD\r"
      expect "Do you wish to continue with the password provided?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect "Remove anonymous users?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect "Disallow root login remotely?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect "Remove test database and access to it?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect "Reload privilege tables now?\(Press y\|Y for Yes, any other key for No\) :"
      send "y\r"
      expect eof
      ")
      echo "$SECURE_MYSQL"
export MYSQL_ZABBIX_PASSWORD=q1w2e3r4t5y6
sudo mysql -u root --password=$MYSQL_ZABBIX_PASSWORD <<MYSQL_SCRIPT
create database zabbix character set utf8 collate utf8_bin;
create user zabbix@localhost identified by 'q1w2e3r4t5y6';
grant all privileges on zabbix.* to zabbix@localhost;
FLUSH PRIVILEGES;
quit;
MYSQL_SCRIPT
sudo firewall-cmd --add-port=3306/tcp --permanent && sudo firewall-cmd --reload
###INSTALARION ZABBIX
#sudo yum install -y https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
#sudo yum install zabbix-server-mysql zabbix-agent zabbix-get
#sudo yum-config-manager --enable zabbix-frontend
#sudo yum -y install centos-release-scl
#sudo yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl
#zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix --password=q1w2e3r4t5y6u7i8 zabbix
#sudo sed -i 's/^DBName=.*/DBName=zabbix/g' /etc/httpd/conf/httpd.conf
#sudo sed -i 's/^DBUser=.*/DBUser=zabbix/g' /etc/httpd/conf/httpd.conf
#sudo sed -i 's/^DBPassword=.*/DBPassword=q1w2e3r4t5y6u7i8/g' /etc/httpd/conf/httpd.conf
#echo "php_value[date.timezone] = America/Fortaleza" >> /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
#sudo systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
#sudo systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm
#sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
#sudo firewall-cmd --reload
#sudo systemctl restart httpd

###INSTALAR ZABBIX
sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
sudo dnf -y clean all
sudo dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent zabbix-get
sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix --password=q1w2e3r4t5y6 zabbix
sudo sed -i "s|^# DBPassword=|DBPassword=${MYSQL_ZABBIX_PASSWORD}|g" /etc/zabbix/zabbix_server.conf
sudo echo "php_value[date.timezone] = America/Fortaleza" >> /etc/php-fpm.d/zabbix.conf
sudo systemctl restart zabbix-server zabbix-agent httpd php-fpm
sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm
sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent && sudo firewall-cmd --reload
###CONFIG HTTPD
sudo echo -e "ServerSignature Off \nServerTokens Prod" >> /etc/httpd/conf/httpd.conf
sudo sed -i 's/^#ServerName.*/ServerName zabbix.labary.local/g' /etc/httpd/conf/httpd.conf
sudo firewall-cmd --add-service={http,https} --permanent && sudo firewall-cmd --reload
sudo reboot