#!/bin/bash
. /root/environment_compute.sh

yum install openstack-nova-compute -y
crudini --set /etc/nova/nova.conf DEFAULT	enabled_apis  osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT	transport_url  rabbit://openstack:$PW_MQ@$IP_MANAGER_CONTROLLER
crudini --set /etc/nova/nova.conf DEFAULT	my_ip  $IP_MANAGER
crudini --set /etc/nova/nova.conf DEFAULT	use_neutron  True
crudini --set /etc/nova/nova.conf DEFAULT	firewall_driver  nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf keystone_authtoken	auth_uri  http://$IP_MANAGER_CONTROLLER:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken	auth_url  http://$IP_MANAGER_CONTROLLER:35357
crudini --set /etc/nova/nova.conf keystone_authtoken	memcached_servers  $IP_MANAGER_CONTROLLER:11211
crudini --set /etc/nova/nova.conf keystone_authtoken	auth_type  password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken	project_name  service
crudini --set /etc/nova/nova.conf keystone_authtoken	username  nova
crudini --set /etc/nova/nova.conf keystone_authtoken	password  $PW_SV
crudini --set /etc/nova/nova.conf api auth_strategy keystone
crudini --set /etc/nova/nova.conf vnc	enabled  True
crudini --set /etc/nova/nova.conf vnc	vncserver_listen  0.0.0.0
crudini --set /etc/nova/nova.conf vnc	vncserver_proxyclient_address   \$my_ip
crudini --set /etc/nova/nova.conf vnc	novncproxy_base_url  http://$IP_PROVIDER_MANAGER:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers http://$IP_MANAGER_CONTROLLER:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement	os_region_name  RegionOne
crudini --set /etc/nova/nova.conf placement	project_domain_name  Default
crudini --set /etc/nova/nova.conf placement	project_name  service
crudini --set /etc/nova/nova.conf placement	auth_type  password
crudini --set /etc/nova/nova.conf placement	user_domain_name  Default
crudini --set /etc/nova/nova.conf placement	auth_url  http://$IP_MANAGER_CONTROLLER:35357/v3
crudini --set /etc/nova/nova.conf placement	username  placement
crudini --set /etc/nova/nova.conf placement	password  $PW_SV
vtx=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $vtx == 0 ]; then
crudini --set /etc/nova/nova.conf libvirt	virt_type  qemu
crudini --set /etc/nova/nova.conf libvirt	cpu_mode  none
else
crudini --set /etc/nova/nova.conf libvirt	virt_type  kvm
crudini --set /etc/nova/nova.conf libvirt	cpu_mode  none
fi

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service

