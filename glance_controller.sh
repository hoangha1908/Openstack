#!/bin/bash
. /root/environment_controller.sh

openstack user create --domain default --password $PW_SV glance
openstack role add --project service --user glance admin
openstack service create --name glance   --description "OpenStack Image" image
openstack endpoint create --region RegionOne   image public http://$IP_MANAGER:9292
openstack endpoint create --region RegionOne   image internal http://$IP_MANAGER:9292
openstack endpoint create --region RegionOne   image admin http://$IP_MANAGER:9292

yum install openstack-glance -y
crudini --set /etc/glance/glance-api.conf DEFAULT bind_host   0.0.0.0
crudini --set /etc/glance/glance-api.conf DEFAULT bind_port   9292
crudini --set /etc/glance/glance-api.conf DEFAULT transport_url   rabbit://openstack:$PW_MQ@$IP_MANAGER
crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend   rabbit
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$PW_DB@$IP_MANAGER/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri  http://$IP_MANAGER:5000/v3
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://$IP_MANAGER:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers  $IP_MANAGER:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type  password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name  service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $PW_SV
crudini --set /etc/glance/glance-api.conf keystone_authtoken service_token_roles_required true
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone 
crudini --set /etc/glance/glance-api.conf glance_store stores   file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store   file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir   /var/lib/glance/images/
crudini --set  /etc/glance/glance-registry.conf DEFAULT bind_host   0.0.0.0
crudini --set /etc/glance/glance-registry.conf DEFAULT bind_port   9191
crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver   noop
crudini --set /etc/glance/glance-registry.conf DEFAULT transport_url   rabbit://openstack:$PW_MQ@$IP_MANAGER
crudini --set /etc/glance/glance-registry.conf DEFAULT rpc_backend   rabbit
crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$PW_DB@$IP_MANAGER/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri   http://$IP_MANAGER:5000/v3
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url   http://$IP_MANAGER:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers   $IP_MANAGER:11211
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type   password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name   service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username   glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $PW_SV
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone 
su -s /bin/bash glance -c "glance-manage db_sync"
systemctl enable openstack-glance-api.service   openstack-glance-registry.service
systemctl restart openstack-glance-api.service   openstack-glance-registry.service
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create "cirros"   --file cirros-0.3.5-x86_64-disk.img   --disk-format qcow2 --container-format bare   --public
openstack image list
echo "Da cai dat xong Glance va import image cirros"

