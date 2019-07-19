#!/bin/bash
. /root/environment_controller.sh

openstack user create --domain default --password $PW_SV neutron
openstack role add --project service --user neutron admin

openstack service create --name neutron   --description "OpenStack Networking" network
openstack endpoint create --region RegionOne   network public http://$IP_MANAGER:9696
openstack endpoint create --region RegionOne   network internal http://$IP_MANAGER:9696
openstack endpoint create --region RegionOne   network admin http://$IP_MANAGER:9696

yum install openstack-neutron openstack-neutron-ml2   openstack-neutron-linuxbridge ebtables -y

crudini --set  /etc/neutron/neutron.conf DEFAULT bind_host   0.0.0.0
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy   keystone
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins   
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url   rabbit://openstack:$PW_MQ@$IP_MANAGER
crudini --set  /etc/neutron/neutron.conf DEFAULT rpc_backend   rabbit
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes   true
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes   true
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	auth_uri  http://$IP_MANAGER:5000/v3
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	auth_url  http://$IP_MANAGER:35357
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	memcached_servers  $IP_MANAGER:11211
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	auth_type  password
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	project_name  service
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	username  neutron
crudini --set  /etc/neutron/neutron.conf keystone_authtoken	password  $PW_SV
crudini --set /etc/neutron/neutron.conf database connection    mysql+pymysql://neutron:$PW_DB@$IP_MANAGER/neutron
crudini --set  /etc/neutron/neutron.conf nova	auth_url  http://$IP_MANAGER:35357
crudini --set  /etc/neutron/neutron.conf nova	auth_type  password
crudini --set  /etc/neutron/neutron.conf nova	project_domain_name  default
crudini --set  /etc/neutron/neutron.conf nova	user_domain_name  default
crudini --set  /etc/neutron/neutron.conf nova	region_name  RegionOne
crudini --set  /etc/neutron/neutron.conf nova	project_name  service
crudini --set  /etc/neutron/neutron.conf nova	username  nova
crudini --set  /etc/neutron/neutron.conf nova	password  $PW_SV
crudini --set  /etc/neutron/neutron.conf oslo_concurrency  lock_path  /var/lib/neutron/tmp
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 	type_drivers  flat,vlan
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 	tenant_network_types 
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2	             mechanism_drivers  linuxbridge
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2	             extension_drivers  port_security
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat	flat_networks  provider
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup	enable_ipset true 
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge	physical_interface_mappings  provider:$INTERFACE_NAME_PROVIDER
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan false
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
crudini --set  /etc/neutron/dhcp_agent.ini DEFAULT	interface_driver  linuxbridge
crudini --set  /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set  /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true
crudini --set  /etc/neutron/metadata_agent.ini DEFAULT	nova_metadata_ip  $IP_MANAGER
crudini --set  /etc/neutron/metadata_agent.ini DEFAULT	metadata_proxy_shared_secret proxy
crudini --set /etc/nova/nova.conf neutron	url http://$IP_MANAGER:9696
crudini --set /etc/nova/nova.conf neutron	auth_url http://$IP_MANAGER:35357/v3
crudini --set /etc/nova/nova.conf neutron	auth_type password
crudini --set /etc/nova/nova.conf neutron	project_domain_name default
crudini --set /etc/nova/nova.conf neutron	user_domain_name default
crudini --set /etc/nova/nova.conf neutron	region_name RegionOne
crudini --set /etc/nova/nova.conf neutron	project_name service
crudini --set /etc/nova/nova.conf neutron	username neutron
crudini --set /etc/nova/nova.conf neutron	password $PW_SV
crudini --set /etc/nova/nova.conf neutron	service_metadata_proxy true
crudini --set /etc/nova/nova.conf neutron	metadata_proxy_shared_secret proxy

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
 su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service   neutron-linuxbridge-agent.service neutron-dhcp-agent.service   neutron-metadata-agent.service
systemctl restart neutron-server.service   neutron-linuxbridge-agent.service neutron-dhcp-agent.service   neutron-metadata-agent.service
openstack extension list --network
openstack network agent list
echo "Da cai xong neutron"

