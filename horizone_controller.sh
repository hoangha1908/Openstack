#!/bin/bash
. /root/environment_controller.sh

yum install openstack-dashboard -y
yes | cp ~/config_openstack/local_settings /etc/openstack-dashboard/
sed -i "s/controller/$IP_MANAGER/" /etc/openstack-dashboard/local_settings
systemctl restart httpd.service memcached.service
echo "Cai dat xong Horizon"

