#!/bin/bash

### INSTALAÇãO DE DEPEDENCIAS: ###
#sudo apt -y install cairo-devel freerdp-devel gcc java-1.8.0-openjdk.x86_64 libguac libguac-client-rdp libguac-client-ssh \
#libguac-client-vnc libjpeg-turbo-devel libwebsockets-devel libpng-devel libssh2-devel libtelnet-devel libvncserver-devel libtool \
#libvorbis-devel libwebp-devel openssl-devel pango-devel pulseaudio-libs-devel terminus-fonts \
#tomcat-admin-webapps tomcat-webapps uuid-devel libtelnet libtelnet-devel install mariadb mariadb-server -y

sudo apt -y install gcc vim curl wget g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev \
libavformat-dev libavutil-dev libswscale-dev build-essential libpango1.0-dev libssh2-1-dev \
libvncserver-dev libtelnet-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev ffmpeg ffmpeg-devel \
openjdk-8-jdk tomcat9

### BIXANDO GUACAMOLE ###
sudo mkdir /opt/temp/
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz\?action\=download -O /opt/temp/guacamole-server-1.3.0.tar.gz
sudo tar -xzf /opt/temp/guacamole-server-1.3.0.tar.gz -C /opt/temp/
cd /opt/temp/guacamole-server-1.3.0/ && sudo ./configure --with-init-dir=/etc/init.d
cd /opt/temp/guacamole-server-1.3.0/ && sudo make
cd /opt/temp/guacamole-server-1.3.0/ && sudo make install && sudo ldconfig
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/binary/guacamole-1.3.0.war?action=download -O /var/lib/tomcat/webapps/guacamole.war
systemctl enable guacd tomcat.service
###CONFIGURANDO BANCO ###
#sudo apt install -y https://download.postgresql.org/pub/repos/apt/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
#sudo apt install -y postgresql11-server
#sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
s#udo systemctl enable postgresql-11 && sudo systemctl start postgresql-11
sudo mkdir -p /usr/share/tomcat/.guacamole/{extensions,lib}
sudo wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/binary/guacamole-auth-jdbc-1.3.0.tar.gz?action=download -O /opt/temp/guacamole-auth-jdbc-1.3.0.tar.gz
sudo tar -xzf /opt/temp/guacamole-auth-jdbc-1.3.0.tar.gz -C /opt/temp/
cp /opt/temp/guacamole-auth-jdbc-1.3.0/postgresql/guacamole-auth-jdbc-postgresql-1.3.0.jar /usr/share/tomcat/.guacamole/extensions/
sudo wget https://jdbc.postgresql.org/download/postgresql-42.2.24.jar -O /usr/share/tomcat/.guacamole/lib/postgresql-42.2.24.jar
sudo su - postgres -c "psql <<POSTGRES_SCRIPT
ALTER USER POSTGRES WITH PASSWORD '8ymC^#UvjkLbGZsY';
CREATE DATABASE guacamole_db;
\q
POSTGRES_SCRIPT"
sudo su - postgres -c "cat /opt/temp/guacamole-auth-jdbc-1.3.0/postgresql/schema/*.sql | psql -d guacamole_db -f -"
sudo su - postgres -c "psql -d guacamole_db <<POSTGRES_SCRIPT
CREATE USER guacamole_user WITH PASSWORD 'WC#vcb!G3uF(E@N8';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO guacamole_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO guacamole_user;
\q
POSTGRES_SCRIPT"
sed -i '82,84s/ident/md5/' /var/lib/pgsql/11/data/pg_hba.conf
sudo systemctl reload postgresql-15.service
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
postgresql-password: WC#vcb!G3uF(E@N8
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