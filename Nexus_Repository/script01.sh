#!/bin/bash
sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="no"
IPADDR=192.168.1.207
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=1.1.1.1
EOF
sudo /etc/init.d/network restart
sudo echo "nexus" > /etc/hostname 						
sudo yum update -y 
sudo yum install -y epel-release ; yum update -y 
sudo yum install -y wget perl iotop net-tools htop nfs-utils git vim wget net-tools java-1.8.0-openjdk.x86_64 
sudo mkdir /opt/nexus/ && cd /opt/nexus/ && sudo wget http://download.sonatype.com/nexus/3/nexus-3.28.1-01-unix.tar.gz 
sudo tar -xzvf /opt/nexus/nexus-3.28.1-01-unix.tar.gz && mv /opt/nexus/nexus-3.28.1-01 nexus && mv /opt/nexus/sonatype-work nexusdata 
sudo useradd --system --no-create-home nexus && sudo chown -R nexus:nexus /opt/nexus/ 
sudo cat > /opt/nexus/nexus/bin/nexus.vmoptions << EOF
-Xms2703m
-Xmx2703m
-XX:MaxDirectMemorySize=2703m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../nexusdata/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../nexusdata/nexus3
-Dkaraf.log=../nexusdata/nexus3/log
-Djava.io.tmpdir=../nexusdata/nexus3/tmp
-Dkaraf.startLocalConsole=false
EOF
sudo echo 'run_as_user="nexus"' > /opt/nexus/nexus/bin/nexus.rc    
sudo sed -i "s/application-host=0.0.0.0/application-host=192.168.1.207/g" /opt/nexus/nexus/etc/nexus-default.properties 
sudo echo "nexus - nofile 65536" >> vim /etc/security/limits.conf            
sudo cat > /etc/systemd/system/nexus.service << EOF
[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/nexus/bin/nexus start
ExecStop=/opt/nexus/nexus/bin/nexus stop
User=nexus
Group=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable nexus.service firewalld && systemctl start nexus.service firewalld
sudo firewall-cmd --zone=public --permanent --add-port=8081/tcp && sudo firewall-cmd --reload 
sudo reboot