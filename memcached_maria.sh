#!/bin/bash
. /root/environment_controller.sh

echo "Tien hanh cai dat MariaDB"
yum install mariadb mariadb-server python2-PyMySQL -y
echo "[mysqld]"  >> /etc/my.cnf.d/openstack.cnf
echo "bind-address = $IP_MANAGER"  >> /etc/my.cnf.d/openstack.cnf
echo "default-storage-engine = innodb"  >> /etc/my.cnf.d/openstack.cnf
echo "innodb_file_per_table = on"  >> /etc/my.cnf.d/openstack.cnf
echo "max_connections = 4096"  >> /etc/my.cnf.d/openstack.cnf
echo "collation-server = utf8_general_ci"  >> /etc/my.cnf.d/openstack.cnf
echo "character-set-server = utf8"  >> /etc/my.cnf.d/openstack.cnf
systemctl enable mariadb.service
systemctl restart mariadb.service
mysqladmin -u root password $PW_DB

echo "Tien hanh cai RabbitMQ"
yum install rabbitmq-server -y
systemctl enable rabbitmq-server.service
systemctl restart rabbitmq-server.service
rabbitmqctl add_user openstack $PW_MQ
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
yum install memcached python-memcached -y
echo "Tien hanh cai Memcache"
sed -i 's/MAXCONN="1024"/MAXCONN="2048"/g' /etc/sysconfig/memcached
sed -i 's/OPTIONS="-l 127.0.0.1,::1/OPTIONS="-l '$IP_MANAGER',::1/g' /etc/sysconfig/memcached
systemctl enable memcached.service
systemctl restart memcached.service

mysql -u root --password=$PW_DB -e 'CREATE DATABASE keystone;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON keystone.* TO "keystone"@"%"  IDENTIFIED BY "'$PW_DB'" 
WITH GRANT OPTION;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON keystone.* TO "keystone"@"controller"  IDENTIFIED BY "'$PW_DB'" WITH GRANT OPTION;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON keystone.* TO "keystone"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'CREATE DATABASE glance;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON glance.* TO "glance"@"%"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON glance.* TO "glance"@"controller"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON glance.* TO "glance"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'CREATE DATABASE nova_api;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_api.* TO "nova"@"%"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_api.* TO "nova"@"controller"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_api.* TO "nova"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'CREATE DATABASE nova;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova.* TO "nova"@"%"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova.* TO "nova"@"controller"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova.* TO "nova"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'CREATE DATABASE nova_cell0;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_cell0.* TO "nova"@"%"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_cell0.* TO "nova"@"controller"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON nova_cell0.* TO "nova"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'CREATE DATABASE neutron;'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON neutron.* TO "neutron"@"%"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON neutron.* TO "neutron"@"controller"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'GRANT ALL PRIVILEGES ON neutron.* TO "neutron"@"localhost"  IDENTIFIED BY "'$PW_DB'";'
mysql -u root --password=$PW_DB -e 'flush privileges;'

echo "Da cai dat xong va tao toan bo database"

