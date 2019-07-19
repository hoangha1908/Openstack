#!/bin/bash
#Set IP + Password
IP_PROVIDER=172.20.80.170
PREFIX_PROVIDER=24
GATEWAY=172.20.80.250
INTERFACE_NAME_PROVIDER=ens32
IP_MANAGER=10.100.10.120
PREFIX_MANAGER=24
INTERFACE_NAME_MANAGER=ens33
PW_DB=hoangha1908
PW_SV=hoangha1908
PW_MQ=hoangha1908
#Export Value
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PW_SV
export OS_AUTH_URL=http://$IP_MANAGER:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2


if [ -f /root/config_base ]; then
echo "^^ Cai dat IP da duoc thuc hien"
else
echo "^^ Tien hanh cai dat IP"
yum -y install vim wget net-tools centos-release-openstack-ocata git
yum install openstack-utils -y
hostnamectl set-hostname controller
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.addresses $IP_PROVIDER/$PREFIX_PROVIDER
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.gateway $GATEWAY
nmcli c modify $INTERFACE_NAME_PROVIDER ipv4.method manual
nmcli c modify $INTERFACE_NAME_PROVIDER connection.autoconnect yes
nmcli c modify $INTERFACE_NAME_MANAGER ipv4.addresses $IP_MANAGER/$PREFIX_MANAGER
nmcli c modify $INTERFACE_NAME_MANAGER ipv4.method manual
nmcli c modify $INTERFACE_NAME_MANAGER connection.autoconnect yes
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
yum install chrony -y
echo "allow 0/0" >> /etc/chrony.conf
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

