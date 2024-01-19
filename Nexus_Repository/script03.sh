#!/bin/bash

DIRNEXUS="/opt/Nexus"
HOSTNAME="srv-nexus-repository"

sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo setenforce 0

export NEXUS_HOME=/opt/nexus
source /etc/bashrc
sudo echo "$HOSTNAME" > /etc/hostname
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum update -y 
sudo yum install -y epel-release
sudo yum install -y wget perl iotop htop vim java-1.8.0-openjdk.x86_64 -y
sudo mkdir -p $DIRNEXUS/{app,data}
sudo wget http://download.sonatype.com/nexus/3/nexus-3.38.1-01-unix.tar.gz 
sudo tar -xzvf nexus-3.38.1-01-unix.tar.gz && \
sudo mv nexus-3.38.1-01/* $DIRNEXUS/app/. && mv sonatype-work/nexus3/* $DIRNEXUS/data.
sudo useradd --system -d $DIRNEXUS nexus && sudo chown -R nexus:nexus $DIRNEXUS/
sudo cat > $DIRNEXUS/app/bin/nexus.vmoptions << EOF
-Xms256m
-Xmx256m
-XX:MaxDirectMemorySize=256m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=$DIRNEXUS/data/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=. 
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=$DIRNEXUS/data
-Dkaraf.log=$DIRNEXUS/data/log
-Djava.io.tmpdir=$DIRNEXUS/data/tmp
-Dkaraf.startLocalConsole=false
EOF
sudo echo 'run_as_user="nexus"' > $DIRNEXUS/app/bin/nexus.rc    
sudo sed -i "s/application-host=0.0.0.0/application-host=129.213.112.173/g" $DIRNEXUS/app/etc/nexus-default.properties 
sudo echo "nexus - nofile 65536" >> vim /etc/security/limits.conf            
sudo cat > /etc/systemd/system/nexus.service << EOF
[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=$DIRNEXUS/app/bin/nexus start
ExecStop=$DIRNEXUS/app/bin/nexus stop
User=nexus
Group=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
sudo chown nexus:nexus -R $DIRNEXUS/
sudo systemctl daemon-reload && sudo systemctl enable nexus.service firewalld && systemctl start nexus.service firewalld
sudo firewall-cmd --zone=public --permanent --add-port=8081/tcp && sudo firewall-cmd --reload 