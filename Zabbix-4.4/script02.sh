#!/bin/bash
###ENVs
DB_ZABBIX_PASSWORD="KeVFbH%7}:W2"
###ENVs
###UTILS
sudo yum update -y && sudo yum install -y epel-release 
sudo yum install -y expect vim htop git wget mlocate
###INSTALL POSTGRES
#sudo rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm && yum clean -y all
#sudo rpm -Uvh https://downloads.mysql.com/archives/get/p/23/file/mysql-community-client-8.0.22-1.el7.x86_64.rpm && yum clean -y all
#sudo yum install -y mysql 
#sudo firewall-cmd --add-port=3306/tcp --permanent && sudo firewall-cmd --reload
sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum -y install postgresql13-server postgresql13
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
sudo systemctl start postgresql-13 && sudo systemctl enable postgresql-13
sudo firewall-cmd --add-port=5432/tcp --permanent && sudo firewall-cmd --reload

### INSTALAR ZABBIX ###
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo yum install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-agent zabbix-get nginx php-fpm && yum clean all -y
### CONFIG POSTGRES ###
sudo su - postgres -c "psql <<POSTGRES_SCRIPT 
ALTER USER POSTGRES WITH PASSWORD 'q1w2e3r4t5y6u7i8';
POSTGRES_SCRIPT"
zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix

###CONFIG ZABBIX
sudo sed -i "s|^# DBPassword=|DBPassword=${DB_ZABBIX_PASSWORD}|g" /etc/zabbix/zabbix_server.conf
sudo sed -i "s|^# DBHost=|DBHost=192.168.1.210|g" /etc/zabbix/zabbix_server.conf
sudo sed -i 's/;date.timezone =/date.timezone = America/Fortaleza/g' /etc/php.ini
###CONFIG SERVICES & Firewalld
sudo systemctl restart zabbix-server zabbix-agent httpd 
sudo systemctl enable zabbix-server zabbix-agent httpd
sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent && sudo firewall-cmd --reload
###CONFIG HTTPD
sudo echo -e "ServerSignature Off \nServerTokens Prod" >> /etc/httpd/conf/httpd.conf
sudo sed -i 's/^#ServerName.*/ServerName zabbix.labary.local/g' /etc/httpd/conf/httpd.conf
sudo firewall-cmd --add-service={http,https} --permanent && sudo firewall-cmd --reload
###Utils
sudo updatedb