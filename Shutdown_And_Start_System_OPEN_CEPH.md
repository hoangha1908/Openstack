# Hướng dẫn Tắt + Bật hệ thống Openstack và Ceph theo đúng quy trình

## 1. Mục tiêu 
- Giảm thiểu thời gian xử lý lỗi phát sinh trong quá trình Tắt + Bật hệ thống

## 3. Môi trường
- Giả xử hệ thống gồm
- Openstack: 3 Node Controller (Controller1, Controller2, Controller3) + 1 Node Compute
- Ceph: 3 Node (Ceph1, Ceph2, Ceph3)

## 4. Thực hiện

### 4.1 Lưu ý
- Thời gian giữa các bước phụ thuộc vào tốc độ shutdown và start của server
- Đối với hệ thống Lab hiện tại thì shutdown các Node Controller cần cách nhau 5'
- Khi Start Controller thì cần tối thiểu 10' để các dịch vụ khởi động lên hết
- Nếu có điều kiện thì tắt các Máy ảo trước

### 4.2 Shutdown hệ thống
- Bước 1: Controller1: Đưa Pacemaker vào chế độ Maintenance
  * pcs property set maintenance-mode=true
- Bước 2: Controller1: Poweroff
- Bước 3: Controller2: Poweroff
- Bước 4: Controller3: Poweroff
- Bước 5: Compute: Poweroff (Các Node Compute có thể shutdown đồng thời)
- Bước 6: Ceph1: Đưa Ceph vào chế độ Maintenance
  * ceph osd set noout
- Bước 7: Poweroff đồng thời tắt cả các Ceph Node

### 4.3 Start hệ thống
- Bước 1: Khởi động toàn bộ Node Ceph
- Bước 2: Ceph1: Kiểm tra lại trạng thái hệ thống đã online hết chưa (ceph -s)
- Bước 3: Ceph1: Trả Ceph về trạng thái bình thường
  * ceph osd unset noout
- Bước 4: Bật Controller3
- Bước 5: Bật Controller2
- Bước 5: Bật Controller1
- Bước 6: Controller1: Bật MariaDB
  * galera_new_cluster
- Bước 7: Controler2: Bật MariaDB
  * systemctl start mariadb
- Bước 8: Controller3: Bật MariaDB
  * systemctl start mariadb
- Bước 9: Tiến hành Reboot lần lượt các Controller Node (3,2,1). Mục đích để dịch vụ khi start sẽ kết nối được vào Database
- Bước 10: Kiểm tra lại toàn bộ dịch vụ của Openstack, Pamaceker, MariaDB, RabbitMQ
- Bước 11: Bật các Node Compute
- Bước 12: Kiểm tra lại dịch vụ Compute và Neutron
- Hoàn tất quá trình

### 5. Đối với hệ thống LAB hiện tại thì shutdown theo thứ tự sau
- Controller 04 (172.20.30.224 gồm MariaDB + RabbitMQ + Openstack)
- Controller 01 (172.20.30.221 gồm MariaDB + RabbitMQ + Openstack)
- Controller 00 (172.20.30.220 chạy RabbitMQ)
- Compute 02 (172.20.30.222)
- Compute 03 (172.20.30.223)
 






