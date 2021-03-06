#!/bin/bash
. /root/environment_compute.sh

yum install openstack-neutron-linuxbridge ebtables ipset -y

crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$PW_MQ@$IP_MANAGER_CONTROLLER
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken	auth_uri  http://$IP_MANAGER_CONTROLLER:5000/v3
crudini --set /etc/neutron/neutron.conf keystone_authtoken	auth_url  http://$IP_MANAGER_CONTROLLER:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken	memcached_servers  $IP_MANAGER_CONTROLLER:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken	auth_type  password
crudini --set /etc/neutron/neutron.conf keystone_authtoken	project_domain_name  default
crudini --set /etc/neutron/neutron.conf keystone_authtoken	user_domain_name  default
crudini --set /etc/neutron/neutron.conf keystone_authtoken	project_name  service
crudini --set /etc/neutron/neutron.conf keystone_authtoken	username  neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken	password  $PW_SV
crudini --set /etc/neutron/neutron.conf oslo_concurrency	lock_path  /var/lib/neutron/tmp

crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge	physical_interface_mappings  provider:$INTERFACE_NAME_PROVIDER
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan	enable_vxlan  false
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup	enable_security_group  true
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup	firewall_driver  neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


crudini --set  /etc/nova/nova.conf neutron	url  http://$IP_MANAGER_CONTROLLER:9696
crudini --set  /etc/nova/nova.conf neutron	auth_url  http://$IP_MANAGER_CONTROLLER:35357
crudini --set  /etc/nova/nova.conf neutron	auth_type  password
crudini --set  /etc/nova/nova.conf neutron	project_domain_name  default
crudini --set  /etc/nova/nova.conf neutron	user_domain_name  default
crudini --set  /etc/nova/nova.conf neutron	region_name  RegionOne
crudini --set  /etc/nova/nova.conf neutron	project_name  service
crudini --set  /etc/nova/nova.conf neutron	username  neutron
crudini --set  /etc/nova/nova.conf neutron	password  $PW_SV


systemctl restart openstack-nova-compute.service libvirtd.service 
systemctl enable neutron-linuxbridge-agent.service
systemctl restart neutron-linuxbridge-agent.service
echo "Da cai xong neutron"

