#!/bin/bash
IP_PROVIDER=172.20.80.171
PREFIX_PROVIDER=24
GATEWAY=172.20.80.250
INTERFACE_NAME_PROVIDER=ens32
IP_MANAGER=10.100.10.121
PREFIX_MANAGER=24
INTERFACE_NAME_MANAGER=ens33
PW_DB=hoangha1908
PW_SV=hoangha1908
PW_MQ=hoangha1908
IP_MANAGER_CONTROLLER=10.100.10.120
IP_PROVIDER_MANAGER=172.20.80.170


if [ -f /root/config_base ]; then
echo "^^ Cai dat IP da duoc thuc hien"
else
echo "^^ Tien hanh cai dat IP"
yum -y install vim wget net-tools centos-release-openstack-ocata git
yum install openstack-utils -y
hostnamectl set-hostname compute1
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.addresses $IP_PROVIDER/$PREFIX_PROVIDER
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.gateway $GATEWAY
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.method manual
nmcli c modify $INTERFACE_NAME_PROVIDER connection.autoconnect yes
nmcli c modify $INTERFACE_NAME_MANAGER ipv4.addresses $IP_MANAGER/$PREFIX_MANAGER
nmcli c modify $INTERFACE_NAME_MANAGER ipv4.method manual
nmcli c modify $INTERFACE_NAME_MANAGER connection.autoconnect yes
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
yum install chrony -y
sed  -i.bak '/server/d' /etc/chrony.conf
echo "server $IP_MANAGER_CONTROLLER iburst" >> /etc/chrony.conf
systemctl enable chronyd.service
systemctl restart chronyd.service
sudo systemctl disable firewalld
sudo systemctl stop firewalld
yum upgrade -y
yum install python-openstackclient openstack-selinux  -y
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network
systemctl mask NetworkManager
yum remove postfix NetworkManager NetworkManager-libnm -y
echo "Ket thuc cai dat IP"
touch /root/config_base
reboot
fi

