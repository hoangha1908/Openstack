#!/bin/bash
. /root/environment_controller.sh


openstack user create --domain default --project service --password $PW_SV nova
openstack role add --project service --user nova admin
openstack user create --domain default --project service --password $PW_SV placement
openstack role add --project service --user placement admin
openstack service create --name nova --description "OpenStack Compute service" compute
openstack service create --name placement --description "OpenStack Compute Placement service" placement
openstack endpoint create --region RegionOne compute public http://$IP_MANAGER:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal  http://$IP_MANAGER:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin   http://$IP_MANAGER:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne placement public http://$IP_MANAGER:8778/placement
openstack endpoint create --region RegionOne placement internal  http://$IP_MANAGER:8778/placement
openstack endpoint create --region RegionOne placement admin   http://$IP_MANAGER:8778/placement


crudini --set  /etc/nova/nova.conf DEFAULT  enabled_apis  osapi_compute,metadata
crudini --set  /etc/nova/nova.conf DEFAULT  my_ip  $IP_MANAGER
crudini --set  /etc/nova/nova.conf DEFAULT  transport_url  rabbit://openstack:$PW_MQ@$IP_MANAGER
crudini --set  /etc/nova/nova.conf DEFAULT  rpc_backend rabbit
crudini --set  /etc/nova/nova.conf DEFAULT  use_neutron  True
crudini --set  /etc/nova/nova.conf DEFAULT  firewall_driver  nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf api_database    connection   mysql+pymysql://nova:$PW_DB@$IP_MANAGER/nova_api
crudini --set /etc/nova/nova.conf database connection   mysql+pymysql://nova:$PW_DB@$IP_MANAGER/nova
crudini --set /etc/nova/nova.conf api auth_strategy keystone 
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri   http://$IP_MANAGER:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url   http://$IP_MANAGER:35357
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers   $IP_MANAGER:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type   password
crudini --set /etc/nova/nova.conf keystone_authtoken project_name   service
crudini --set /etc/nova/nova.conf keystone_authtoken username   nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $PW_SV
crudini --set /etc/nova/nova.conf glance api_servers http://$IP_MANAGER:9292 
crudini --set  /etc/nova/nova.conf vnc  enabled  true
crudini --set  /etc/nova/nova.conf vnc  vncserver_listen  \$my_ip
crudini --set  /etc/nova/nova.conf vnc  vncserver_proxyclient_address  \$my_ip
crudini --set  /etc/nova/nova.conf oslo_concurrency  lock_path  /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf placement	os_region_name  RegionOne
crudini --set /etc/nova/nova.conf placement	project_domain_name  Default
crudini --set /etc/nova/nova.conf placement	project_name  service
crudini --set /etc/nova/nova.conf placement	auth_type  password
crudini --set /etc/nova/nova.conf placement	user_domain_name  Default
crudini --set /etc/nova/nova.conf placement	auth_url  http://$IP_MANAGER:35357/v3
crudini --set /etc/nova/nova.conf placement	username  placement
crudini --set /etc/nova/nova.conf placement	password  $PW_SV
crudini --set /etc/nova/nova.conf wsgi	api_paste_config  /etc/nova/api-paste.ini
chgrp nova /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
systemctl restart httpd 
nova-manage cell_v2 list_cells

systemctl enable openstack-nova-api.service   openstack-nova-consoleauth.service openstack-nova-scheduler.service   openstack-nova-conductor.service openstack-nova-novncproxy.service

systemctl restart openstack-nova-api.service   openstack-nova-consoleauth.service openstack-nova-scheduler.service   openstack-nova-conductor.service openstack-nova-novncproxy.service
openstack compute service list

echo "Da cai xong Nova"

