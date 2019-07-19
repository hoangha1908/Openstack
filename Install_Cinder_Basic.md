# Hướng dẫn cài đặt Cinder

## 1. Mục tiêu LAB
- Cấp phát Block Storage Service sử dụng LVM

## 2. Mô hình
![img](image/topo_cinder_basic_lvm.jpg)

## 3. Chuẩn bị môi trường  
- Hệ thống Openstack [Tham khảo](https://gitlab.hyperlogy.com/ISS-Hyperlogy/OpenStack/blob/master/Ocata_Script/README.md)
- Server cấp phát Block là Compute, yêu cầu có thêm 1 ổ cứng (# ổ cài OS) để cấp phát storage. Lưu ý là server cấp phát storage có thể là bất kì, miễn cùng dải IP với dải Manager của hệ thống Openstack
- Mật khẩu database: hyper123
- Mật khẩu service: hyper123
- IP Manager Controller: 10.100.10.16
- IP Manager Computer: 10.100.10.17

## 4. Cài đặt
- Lưu ý :
  - Tất cả câu lệnh đều thực hiện với quyền `ROOT`  
- Bước 1 - Controller Node: Tạo database Cinder và user có full quyền lên database
  * mysql -u root -p
  * CREATE DATABASE cinder;
  * GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'hyper123';
  * GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'*' IDENTIFIED BY 'hyper123';
  * GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'controller' IDENTIFIED BY 'hyper123';
  * flush privileges
  * exit
- Bước 2 - Controller Node: Tạo user cinder và gán quyền admin
  * openstack user create --domain default --password hyper123 cinder
  * openstack role add --project service --user cinder admin
- Bước 3 - Controller Node: Tạo các endpoint 
  * openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
  * openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
  * openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
  * openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
  * openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s
  * openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
  * openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
  * openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s
- Bước 4 - Controller Node: Cài đặt gói cinder
  * yum install openstack-cinder -y
- Bước 5 - Controller Node: Config các tham số cần thiết
  * crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:hyper123@controller/cinder
  * crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:hyper123@controller
  * crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000/v3
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name  service
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken username  cinder
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken password  hyper123
  * crudini --set /etc/cinder/cinder.conf DEFAULT my_ip 10.100.10.16
  * crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
- Bước 6 - Controller Node: Tạo dữ liệu cho database cinder
  * su -s /bin/sh -c "cinder-manage db sync" cinder
- Bước 7 - All Compute Node: Thêm dòng config sau
  * crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne
- Bước 8 - Controller Node: Restart nova api và start dịch vụ Cinder
  * systemctl restart openstack-nova-api.service
  * systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
  * systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
- Bước 8 - Compute Node: Cài đặt gói lvm
  * yum install lvm2
- Bước 9 - Compute Node: Start service lvm
  * systemctl enable lvm2-lvmetad.service
  * systemctl start lvm2-lvmetad.service
- Bước 10 - Compute Node:Tạo một LVM physical trên /dev/sdb và tạo một LVM volume với tên cinder-volumes
  *  pvcreate /dev/sdb
  *  vgcreate cinder-volumes /dev/sdb
- Bước 11 - Compute Node: Sửa file /etc/lvm/lvm.conf và thêm quyền accept cho ổ sdb  (trong section devices)
```devices {
...
filter = [ "a/sda/", "a/sdb/", "r/.*/"]```
- Bước 12 - Compute Node: Cài thêm gói phần mềm
  * yum install openstack-cinder targetcli python-keystone -y
- Bước 13 - Compute Node: Config các tham số cần thiết 
  * crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:hyper123@controller/cinder
  * crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:hyper123@controller
  * crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000/v3
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name  service
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken username  cinder
  * crudini --set /etc/cinder/cinder.conf keystone_authtoken password  hyper123
  * crudini --set /etc/cinder/cinder.conf DEFAULT my_ip 10.100.10.17
  * crudini --set /etc/cinder/cinder.conf lvm volume_driver   cinder.volume.drivers.lvm.LVMVolumeDriver  
  * crudini --set /etc/cinder/cinder.conf lvm volume_group   cinder-volumes
  * crudini --set /etc/cinder/cinder.conf lvm volume_clear none
  * crudini --set /etc/cinder/cinder.conf lvm iscsi_protocol   iscsi
  * crudini --set /etc/cinder/cinder.conf lvm iscsi_helper   lioadm
  * crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
  * crudini --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://controller:9292
  * crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
- Bước 14 - Compute Node: Start service 
  * systemctl enable openstack-cinder-volume.service target.service
  * systemctl start openstack-cinder-volume.service target.service
 


  
  
  