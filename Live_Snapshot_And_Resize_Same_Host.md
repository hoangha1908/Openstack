# Hướng dẫn cấu hình Live Snapshot, Live Migration, Resize To Same Host

## 1. Mục tiêu LAB
- Snapshot Instance Zero Downtime, Live Migration and Allow Resize To Same Host

## 2. Chuẩn bị môi trường  
- Hệ thống Openstack [Tham khảo](https://gitlab.hyperlogy.com/ISS-Hyperlogy/OpenStack/blob/master/Ocata_Script/README.md)
- Hệ thống Ceph [Tham khảo](https://gitlab.hyperlogy.com/ISS-Hyperlogy/Ceph/blob/master/Docs/Deploy_Ceph_AIO.md)
- Lưu ý: Mặt public của hệ thống Ceph phải cùng dải với mặt Manager của Openstack
- Sử dụng Share Storage lưu trữ Instance

## 3. Cài đặt
- Lưu ý :
  - Tất cả câu lệnh đều thực hiện với quyền `ROOT`  
- Bước 1 - Controller Node: Cấu hình cho phép Resize Same Host
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	allow_resize_to_same_host True
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	allow_migrate_to_same_host True

- Bước 2 - Compute Node: Cấu hình cho phép Resize Same Host
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	allow_resize_to_same_host True
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	allow_migrate_to_same_host True

- Bước 3 - Controller Node: Cấu hình cho phép Live Snapshot
  * crudini  --set /etc/nova/nova.conf	DEFAULT     force_raw_images  True
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	disk_cachemodes  writeback
  * crudini  --set /etc/nova/nova.conf	workarounds 	disable_libvirt_livesnapshot  false
   
- Bước 4 - Compute Node: Cấu hình cho phép Live Snapshot
  * crudini  --set /etc/nova/nova.conf	DEFAULT     force_raw_images  True
  * crudini  --set /etc/nova/nova.conf	DEFAULT 	disk_cachemodes  writeback
  * crudini  --set /etc/nova/nova.conf	workarounds 	disable_libvirt_livesnapshot  false
  
- Bước 5 - Controller Node: Cấu hình cho phép Live Miragation
  * crudini  --set /etc/nova/nova.conf libvirt libvirt_migration_uri qemu+tcp://%s/system 
  * crudini  --set /etc/nova/nova.conf libvirt libvirt_live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
  
- Bước 6 - Controller Node: Sửa file cấu hình của Libvirt trong /etc/libvirt/libvirtd.conf
  * listen_tls = 0
  * listen_tcp = 1
  * auth_tcp = "none"
 
- Bước 7 - Compute Node: Cấu hình cho phép Live Miragation
  * crudini  --set /etc/nova/nova.conf libvirt libvirt_migration_uri qemu+tcp://%s/system 
  * crudini  --set /etc/nova/nova.conf libvirt libvirt_live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
  
- Bước 8 - Compute Node: Sửa file cấu hình của Libvirt trong /etc/libvirt/libvirtd.conf
  * listen_tls = 0
  * listen_tcp = 1
  * auth_tcp = "none"
 
- Bước 9 - Compute Node: Sửa file /etc/sysconfig/libvirtd
  * LIBVIRTD_ARGS="--listen"


