#!/bin/bash
#sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
#DEVICE="eth0"
#BOOTPROTO="static"
#ONBOOT="yes"
#TYPE="Ethernet"
#PERSISTENT_DHCLIENT="no"
#IPADDR=192.168.1.230
#NETMASK=255.255.255.0
#GATEWAY=192.168.1.1
#DNS1=1.1.1.1
#DNS2=192.168.1.200
#EOF
sudo /etc/init.d/network restart
sudo echo "GUACAMOLE" > /etc/hostname 
sudo echo "192.168.1.230 guacamole.labary.local" > /etc/hosts 						
sudo yum update -y 
sudo yum install -y epel-release ; yum update
sudo yum install -y wget git vim htop net-tools mlocate
### INSTALAÇãO DE DEPEDENCIAS: ###
yum -y install cairo-devel freerdp-devel gcc java-1.8.0-openjdk.x86_64 libguac libguac-client-rdp libguac-client-ssh \
libguac-client-vnc libjpeg-turbo-devel libwebsockets-devel libpng-devel libssh2-devel libtelnet-devel libvncserver-devel libtool \
libvorbis-devel libwebp-devel openssl-devel pango-devel pulseaudio-libs-devel terminus-fonts \
tomcat-admin-webapps tomcat-webapps uuid-devel libtelnet libtelnet-devel install mariadb mariadb-server -y
sudo yum groupinstall 'Development Tools' -y
sudo yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
sudo yum install -y ffmpeg ffmpeg-devel
###Instalando Tomcat8 ###
#sudo groupadd tomcat && sudo useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat
#sudo mkdir /opt/tomcat && sudo wget https://downloads.apache.org/tomcat/tomcat-8/v8.5.63/bin/apache-tomcat-8.5.63.tar.gz -O /opt/tomcat/apache-tomcat8.tar.gz
#sudo tar -xvf /opt/tomcat/apache-tomcat8.tar.gz -C /opt/tomcat --strip-components=1 && rm -f /opt/tomcat/apache-tomcat8.tar.gz
#sudo cd /opt/tomcat && sudo chgrp -R tomcat /opt/tomcat
#sudo chmod -R g+r /opt/tomcat/conf && sudo chmod g+x /opt/tomcat/conf
#sudo chown -R tomcat /opt/tomcat/webapps/ /opt/tomcat/work/ /opt/tomcat/temp/ /opt/tomcat/logs/
#sudo cat > /etc/systemd/system/tomcat.service << EOF
# Systemd unit file for tomcat
#[Unit]
#Description=Apache Tomcat Web Application Container
#After=syslog.target network.target
#[Service]
#Type=forking
#Environment=JAVA_HOME=/usr/lib/jvm/jre
#Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
#Environment=CATALINA_HOME=/opt/tomcat
#Environment=CATALINA_BASE=/opt/tomcat
#Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
#Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
#ExecStart=/opt/tomcat/bin/startup.sh
#ExecStop=/bin/kill -15 $MAINPID
#User=tomcat
#Group=tomcat
#UMask=0007
#RestartSec=10
#Restart=always
#[Install]
#WantedBy=multi-user.target
#EOF
#sudo systemctl daemon-reload && sudo systemctl start tomcat && sudo systemctl enable tomcat
###CONFIGURANDO BINARIOS ###
sudo mkdir /opt/temp/
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz\?action\=download -O /opt/temp/guacamole-server-1.3.0.tar.gz
sudo tar -xzf /opt/temp/guacamole-server-1.3.0.tar.gz -C /opt/temp/
cd /opt/temp/guacamole-server-1.3.0/ && sudo ./configure --with-init-dir=/etc/init.d
cd /opt/temp/guacamole-server-1.3.0/ && sudo make
cd /opt/temp/guacamole-server-1.3.0/ && sudo make install && sudo ldconfig
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/binary/guacamole-1.3.0.war?action=download -O /var/lib/tomcat/webapps/guacamole.war
systemctl enable guacd tomcat.service
###CONFIGURANDO BANCO ###
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql11-server
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
sudo systemctl enable postgresql-11 && sudo systemctl start postgresql-11
sudo mkdir -p /usr/share/tomcat/.guacamole/{extensions,lib}
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/binary/guacamole-auth-jdbc-1.3.0.tar.gz?action=download -O /opt/temp/guacamole-auth-jdbc-1.3.0.tar.gz
sudo tar -xzf /opt/temp/guacamole-auth-jdbc-1.3.0.tar.gz -C /opt/temp/
cp /opt/temp/guacamole-auth-jdbc-1.3.0/postgresql/guacamole-auth-jdbc-postgresql-1.3.0.jar /usr/share/tomcat/.guacamole/extensions/
sudo wget https://jdbc.postgresql.org/download/postgresql-42.2.24.jar -O /usr/share/tomcat/.guacamole/lib/postgresql-42.2.24.jar
sudo su - postgres -c "psql <<POSTGRES_SCRIPT
ALTER USER POSTGRES WITH PASSWORD 'q1w2e3r4t5y6u7i8';
CREATE DATABASE guacamole_db;
\q
POSTGRES_SCRIPT"
sudo su - postgres -c "cat /opt/temp/guacamole-auth-jdbc-1.3.0/postgresql/schema/*.sql | psql -d guacamole_db -f -"
sudo su - postgres -c "psql -d guacamole_db <<POSTGRES_SCRIPT
CREATE USER guacamole_user WITH PASSWORD 'q1w2e3r4t5y6';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO guacamole_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO guacamole_user;
\q
POSTGRES_SCRIPT"
sed -i '82,84s/ident/md5/' /var/lib/pgsql/11/data/pg_hba.conf
### CONFIG PROPERTIES FILE ###
mkdir -p /etc/guacamole/
cat > /etc/guacamole/guacamole.properties << COPY
# GUACD CONFIGS
guacd-hostname: localhost
guacd-port: 4822
# MySQL properties
postgresql-hostname: localhost
postgresql-port: 5432
postgresql-database: guacamole_db
postgresql-username: guacamole_user
postgresql-password: q1w2e3r4t5y6
#Additional settings
postgres-default-max-connections-per-user: 0
postgres-default-max-group-connections-per-user: 0
COPY
### CONFIG PERMISSIONS ###
chmod 0400 /etc/guacamole/guacamole.properties
chown tomcat:tomcat /etc/guacamole/guacamole.properties
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/
chown tomcat:tomcat /var/lib/tomcat/webapps/guacamole.war
sudo setenforce 0 
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
updatedb
sudo reboot