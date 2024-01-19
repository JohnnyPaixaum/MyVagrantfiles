#!/bin/bash
#sudo cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
#DEVICE="eth1"
#BOOTPROTO="static"
#ONBOOT="yes"
#TYPE="Ethernet"
#PERSISTENT_DHCLIENT="no"
#IPADDR=192.168.1.211
#NETMASK=255.255.255.0
#GATEWAY=192.168.1.1
#DNS1=1.1.1.1
#EOF
sudo hostnamectl set-hostname BALEIAAZUL
### ATUALIZANDO SISTEMA ###
sudo sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo dnf update -y 
sudo dnf install epel-release -y
### INSTALANDO DOCKER ###
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo -y
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --nobest
sudo usermod -aG docker vagrant
### INSTALANDO PACOTES ESSENCIAIS ###
sudo dnf install -y wget perl iotop net-tools htop git policycoreutils selinux-utils selinux-basics
###
sudo systemctl enable --now firewalld docker
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo firewall-cmd --permanent --zone=public --add-service={docker,sshd}
sudo firewall-cmd --reload