#!/bin/bash
sudo yum update -y && sudo yum install -y epel-release 
sudo yum install -y expect vim htop git wget 
###CONFIG MYSQL
sudo rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm && yum clean -y all
sudo yum install -y mysql-server 
sudo systemctl enable mysqld
sudo firewall-cmd --add-port=3306/tcp --permanent && sudo firewall-cmd --reload
###END
yum clean all -y