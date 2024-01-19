#!/bin/bash

###ENVs
DB_ZABBIX_PASSWORD="KeVFbH%7}:W2"
DB_ZABBIX_IP="localhost"
ZABBIX_HOST_IP="192.168.1.202"
###ENVs

echo "INIT STAP 1"

### ESSENCIALS PACKAGES ###
sudo sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo dnf update -y
sudo dnf install -y epel-release 
sudo dnf install -y vim htop git wget mlocate
sudo setenforce 0

echo "FINISH STAP 1"
echo "INIT STAP 2"

###INSTALL POSTGRES ###
sudo dnf module enable postgresql:13 -y
sudo dnf install -y postgresql-server
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
sudo su - postgres -c "psql <<POSTGRES_SCRIPT 
ALTER USER POSTGRES WITH PASSWORD 'q1w2e3r4t5y6u7i8';
POSTGRES_SCRIPT"

echo "FINISH STAP 2"
echo "INIT STAP 3"

### INSTALAR ZABBIX ###
sudo dnf install -y https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-4.el8.noarch.rpm
sudo dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
sudo dnf clean all -y

echo "FINISH STAP 3"
echo "INIT STAP 4"

### CONFIG POSTGRES ###
#sudo -u postgres createuser --pwprompt zabbix
sudo su - postgres -c "psql <<POSTGRES_SCRIPT
CREATE ROLE zabbix WITH LOGIN PASSWORD '"$DB_ZABBIX_PASSWORD"';
POSTGRES_SCRIPT"
#sudo -u postgres createdb -O zabbix zabbix
sudo su - postgres -c "psql <<POSTGRES_SCRIPT
CREATE DATABASE zabbix OWNER zabbix;
POSTGRES_SCRIPT"
sudo zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

echo "FINISH STAP 4"
echo "INIT STAP 5"

###CONFIG ZABBIX
sudo sed -i 's|^# DBPassword=|DBPassword='"$DB_ZABBIX_PASSWORD"'|g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's|^Hostname=Zabbix Server|Hostname='"$HOST"'|g' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's|^# DBHost=|DBHost='"$DB_ZABBIX_IP"'|g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's|;date.timezone =|date.timezone = America/Fortaleza|g' /etc/php.ini

echo "FINISH STAP 5"
echo "INIT STAP 6"

###CONFIG NGINX
sudo sed -i 's/# listen 8080;/listen 80;/; s/# server_name example.com;/server_name '"$ZABBIX_HOST_IP"';/' /etc/nginx/conf.d/zabbix.conf

echo "FINISH STAP 6"
echo "INIT STAP 7"

###CONFIG SERVICES & Firewalld
sudo systemctl enable --now zabbix-server zabbix-agent nginx firewalld
sudo firewall-cmd --add-port={80/tcp,443/tcp,10051/tcp,10050/tcp} --zone=public --permanent
sudo firewall-cmd --reload

echo "FINISH STAP 7"
echo "INIT STAP 8"

###Utils
sudo updatedb
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "FINISH STAP 8"