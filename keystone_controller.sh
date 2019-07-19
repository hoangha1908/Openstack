#!/bin/bash
. /root/environment_controller.sh

yum install openstack-keystone httpd mod_wsgi -y
crudini --set /etc/keystone/keystone.conf DEFAULT debug   False
crudini --set /etc/keystone/keystone.conf DEFAULT log_dir   /var/log/keystone
crudini --set /etc/keystone/keystone.conf DEFAULT rpc_backend   rabbit
crudini --set /etc/keystone/keystone.conf DEFAULT public_bind_host 0.0.0.0
crudini --set /etc/keystone/keystone.conf DEFAULT admin_bind_host 0.0.0.0
crudini --set /etc/keystone/keystone.conf DEFAULT public_port 5000
crudini --set /etc/keystone/keystone.conf DEFAULT admin_port 35357
crudini --set /etc/keystone/keystone.conf database connection  mysql+pymysql://keystone:$PW_DB@$IP_MANAGER/keystone
crudini --set /etc/keystone/keystone.conf fernet_tokens key_repository /etc/keystone/fernet-keys/
crudini --set /etc/keystone/keystone.conf token provider  fernet
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password $PW_SV --bootstrap-admin-url http://$IP_MANAGER:35357/v3/   --bootstrap-internal-url http://$IP_MANAGER:5000/v3/   --bootstrap-public-url http://$IP_MANAGER:5000/v3/   --bootstrap-region-id RegionOne
yum install openstack-nova-api openstack-nova-conductor   openstack-nova-console openstack-nova-novncproxy   openstack-nova-scheduler openstack-nova-placement-api -y

git clone https://github.com/hoangha1908/config_openstack.git
tar -xvzf ~/config_openstack/conf.tar.gz
yes | cp -r conf/conf /etc/httpd/
yes | cp -r conf/conf.d/ /etc/httpd/
yes | cp -r conf/conf.modules.d/ /etc/httpd/
rm -rf /etc/httpd/conf.d/00-nova-placement-api.conf 
cp -r conf/keystone/ /var/www/cgi-bin/
cp -r conf/nova/ /var/www/cgi-bin/
chown -R keystone:keystone /var/www/cgi-bin/keystone/
chown -R nova:nova /var/www/cgi-bin/nova/
systemctl enable httpd.service
systemctl restart httpd.service
sed -i 's/ admin_token_auth//g' /etc/keystone/keystone-paste.ini
echo "export OS_PROJECT_DOMAIN_NAME=Default" >> admin-openrc
echo "export OS_USER_DOMAIN_NAME=Default" >> admin-openrc
echo "export OS_PROJECT_NAME=admin" >> admin-openrc
echo "export OS_USERNAME=admin" >> admin-openrc
echo "export OS_PASSWORD=$PW_SV" >> admin-openrc
echo "export OS_AUTH_URL=http://$IP_MANAGER:35357/v3" >> admin-openrc
echo "export OS_IDENTITY_API_VERSION=3" >> admin-openrc
echo "export OS_IMAGE_API_VERSION=2" >> admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PW_SV
export OS_AUTH_URL=http://$IP_MANAGER:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
openstack project create --domain default   --description "Service Project" service
openstack project create --domain default   --description "Demo Project" demo
openstack user create --domain default   --password $PW_SV demo
openstack role create user
openstack role add --project demo --user demo user
openstack token issue
echo "Da cai dat xong keystone"
echo "File export moi truong Admin: admin-openrc"

