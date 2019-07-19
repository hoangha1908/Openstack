#!/bin/bash
. /root/environment_controller.sh

#Export Value
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PW_SV
export OS_AUTH_URL=http://$IP_MANAGER:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

openstack hypervisor list
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check


openstack extension list --network
openstack network agent list
echo "File export bien admin  la: admin-openrc"
echo "Truy cap dashboard http://IP_MANAGER/dashboard"
echo "Tai khoan truy cap la admin + password la PW_SV"

