# Hu?ng d?n c�i d?t CEPH s? d?ng `ceph-deploy` tr�n 1 m�y duy nh?t (CEPH AIO)

## 1. M?c ti�u LAB
- M� h�nh n�y s? c�i t?t c? c�c th�nh ph?n c?a CEPH l�n m?t m�y duy nh?t, bao g?m:
  - ceph-deploy
  - ceph-admin
  - mon
  - OSD
- LAB n�y ch? ph� h?p v?i vi?c nghi�n c?c c�c t�nh nang v� demo th? nghi?m, kh�ng �p d?ng du?c trong th?c t?.
- Vi?c d?ng CEPH-AIO c� th? ch?y theo d�ng m� h�nh n�y ho?c theo m� h�nh d? t�ch h?p c�ng OpenStack t?i t�i li?u n�y [link t�i li?u]

## 2. M� h�nh 
- S? d?ng m� h�nh du?i d? c�i d?t CEPH AIO, n?u ch? d?ng CEPH AIO th� ch? c?n m?t m�y ch? d? c�i d?t CEPH. 
![img](images/topology_CEPH_AIO_CentOS7.2.png)

## 3. IP Planning
- Ph�n ho?ch IP cho c�c m�y ch? trong m� h�nh tr�n, n?u ch? d?ng CEPH-AIO th� ch? c?n quan t�m t?i node CEPH-AIO
![img](images/ip-Planning-CEPH_AIO_CentOS7.2.png)

## 4. Chu?n b? v� m�i tru?ng LAB
 
- OS
  - CentOS Server 7.2 64 bit
  - 05: HDD, trong d�:
    - `sda`: s? d?ng d? c�i OS
    - `sdb`: s? d?ng l�m `journal` (Journal l� m?t l?p cache khi client ghi d? li?u, th?c t? thu?ng d�ng ? SSD d? l�m cache)
    - `sdc, sdd, sde`: s? d?ng l�m OSD (noi ch?a d? li?u c?a client)
  - 02 NICs: 
    - `eno16777728`: d�ng client (c�c m�y trong OpenStack) s? d?ng, s? d?ng d?i 10.10.10.0/24
    - `eno33554952`: d�ng d? ssh v� t?i g�i cho m�y ch? CEPH AIO, s? d?ng d?i172.16.69.0/24
    - `eno50332176`: d�ng d? replicate cho CEPH, d?i 10.10.30.0/24
  
- CEPH Jewel

## 5. C�i d?t CEPH tr�n m�y ch? CEPH
- N?u chua login v�o m�y ch? CEPH-AIO b?ng quy?n `root` th� th?c hi?n chuy?n sang quy?n `root`
  ```sh
  su -
  ```

- Update c�c g�i cho m�y ch? 
  ```sh
  yum update -y
  ```

- �?t hostname cho m�y c�i AIO
  ```sh
  hostnamectl set-hostname cephaio  
  ```
- Thi?t l?p IP cho m�y CEPH AIO
  ```sh
  echo "Setup IP  eno16777728"
  nmcli c modify eno16777728 ipv4.addresses 10.10.10.71/24
  nmcli c modify eno16777728 ipv4.method manual
  nmcli con mod eno16777728 connection.autoconnect yes

  echo "Setup IP  eno33554952"
  nmcli c modify eno33554952 ipv4.addresses 172.16.69.71/24
  nmcli c modify eno33554952 ipv4.gateway 172.16.69.1
  nmcli c modify eno33554952 ipv4.dns 8.8.8.8
  nmcli c modify eno33554952 ipv4.method manual
  nmcli con mod eno33554952 connection.autoconnect yes

  echo "Setup IP  eno50332176"
  nmcli c modify eno50332176 ipv4.addresses 10.10.30.71/24
  nmcli c modify eno50332176 ipv4.method manual
  nmcli con mod eno50332176 connection.autoconnect yes
  ```
  
- C?u h�nh c�c th�nh ph?n m?ng co b?n
  ```sh
  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  ```

- V� hi?u h�a Selinux
  ```sh
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  ```

- S?a file host 
  ```sh
  echo "10.10.10.71 cephaio" >> /etc/hosts
  ```

- Kh?i d?ng l?i m�y ch? sau khi c?u h�nh co b?n.
  ```sh
  init 6
  ```
 
- �ang nh?p l?i b?ng quy?n `root` sau khi m�y ch? reboot xong.

- Khai b�o repos cho CEPH 
  ```sh
  sudo yum install -y yum-utils
  sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ 
  sudo yum install --nogpgcheck -y epel-release 
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 
  sudo rm /etc/yum.repos.d/dl.fedoraproject.org*
  ```
   
  ```sh
  cat << EOF > /etc/yum.repos.d/ceph-deploy.repo
  [Ceph-noarch]
  name=Ceph noarch packages
  baseurl=http://download.ceph.com/rpm-jewel/el7/noarch
  enabled=1
  gpgcheck=1
  type=rpm-md
  gpgkey=https://download.ceph.com/keys/release.asc
  priority=1
  EOF
  ```

- Update sau khi khai b�o repo
  ```sh
  sudo yum -y update
  ```
  
- T?o user `ceph-deploy`
  ```sh
  sudo useradd -d /home/ceph-deploy -m ceph-deploy
  ```  
  
- �?t m?t kh?u cho user `ceph-deploy`
  ```sh
  sudo passwd ceph-deploy
  ```
  
- Ph�n quy?n cho user `ceph`
  ```sh
  echo "ceph-deploy ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
  chmod 0440 /etc/sudoers.d/ceph-deploy

  sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
  ```

- Chuy?n sang user `ceph-deploy`
  ```sh
  su - ceph-deploy
  ```

- T?o ssh key cho user `ceph-deploy`
  ```sh
  ssh-keygen -t rsa
  ```

- Th?c hi?n copy ssh key, nh?p yes v� m?t kh?u c?a user `ceph-deploy` ? bu?c tru?c.
  ```sh
  ssh-copy-id ceph-deploy@cephaio
  ```

- C�i d?t `ceph-deploy` 
  ```sh
  sudo yum install -y ceph-deploy
  ```

- T?o thu m?c d? ch?a c�c file c?n thi?t cho vi?c c�i d?t CEPH 
  ```sh
  mkdir cluster-ceph
  cd cluster-ceph
  ```

- Thi?t l?p c�c file c?u h�nh cho CEPH.
  ```sh
  ceph-deploy new cephaio
  ```

- Sau khi th?c hi?n l?nh tr�n xong, s? thu du?c 03 file ? du?i (s? d?ng l?nh `ll -alh` d? xem). Trong d� c?n c?p nh?t file `ceph.conf` d? c�i d?t CEPH du?c ho�n ch?nh.
  ```sh
  [ceph-deploy@cephaio cluster-ceph]$ ls -alh
  total 16K
  drwxrwxr-x. 2 ceph-deploy ceph-deploy   72 Apr 14 09:36 .
  drwx------. 4 ceph-deploy ceph-deploy 4.0K Apr 14 09:36 ..
  -rw-rw-r--. 1 ceph-deploy ceph-deploy  196 Apr 14 09:36 ceph.conf
  -rw-rw-r--. 1 ceph-deploy ceph-deploy 3.0K Apr 14 09:36 ceph-deploy-ceph.log
  -rw-------. 1 ceph-deploy ceph-deploy   73 Apr 14 09:36 ceph.mon.keyring
  ```

- Th�m c�c d�ng du?i v�o file `ceph.conf` v?a du?c t?o ra ? tr�n
  ```sh
  echo "osd pool default size = 2" >> ceph.conf
  echo "osd crush chooseleaf type = 0" >> ceph.conf
  echo "osd journal size = 8000" >> ceph.conf
  echo "public network = 10.10.10.0/24" >> ceph.conf
  echo "cluster network = 10.10.30.0/24" >> ceph.conf
  ```
  
- C�i d?t CEPH, thay `cephaio` b?ng t�n hostname c?a m�y b?n n?u c� thay d?i.
  ```sh
  ceph-deploy install cephaio
  ```
  
  - Sau khi c�i xong, n?u th�nh c�ng s? c� k?t qu? nhu sau.
    ```sh
    [cephaio][DEBUG ] Complete!
    [cephaio][INFO  ] Running command: sudo ceph --version
    [cephaio][DEBUG ] ceph version 10.2.7 (50e863e0f4bc8f4b9e31156de690d765af245185
    ```

- C?u h�nh `MON` (m?t th�nh ph?n c?a CEPH)
  ```sh
  ceph-deploy mon create-initial
  ```

- Sau khi th?c hi?n l?nh d? c?u h�nh `MON` xong, s? sinh th�m ra 04 file : 
  - `ceph.bootstrap-mds.keyring`
  - `ceph.bootstrap-osd.keyring` 
  - `ceph.bootstrap-rgw.keyring`
  - `ceph.client.admin.keyring`

- Quan s�t b?ng l?nh `ll -alh`
  ```sh
  [ceph-deploy@cephaio cluster-ceph]$ ls -lah
  total 160K
  drwxrwxr-x. 2 ceph-deploy ceph-deploy 4.0K Apr 14 10:28 .
  drwx------. 4 ceph-deploy ceph-deploy 4.0K Apr 14 10:18 ..
  -rw-------. 1 ceph-deploy ceph-deploy  113 Apr 14 10:28 ceph.bootstrap-mds.keyring
  -rw-------. 1 ceph-deploy ceph-deploy  113 Apr 14 10:28 ceph.bootstrap-osd.keyring
  -rw-------. 1 ceph-deploy ceph-deploy  113 Apr 14 10:28 ceph.bootstrap-rgw.keyring
  -rw-------. 1 ceph-deploy ceph-deploy  129 Apr 14 10:28 ceph.client.admin.keyring
  -rw-rw-r--. 1 ceph-deploy ceph-deploy  339 Apr 14 10:18 ceph.conf
  -rw-rw-r--. 1 ceph-deploy ceph-deploy  66K Apr 14 10:28 ceph-deploy-ceph.log
  -rw-------. 1 ceph-deploy ceph-deploy   73 Apr 14 10:18 ceph.mon.keyring
  ```

- T?o c�c OSD cho CEPH, thay `cephaio` b?ng t�n hostname c?a m�y b?n 
  ```sh
  ceph-deploy osd prepare cephaio:sdc:/dev/sdb
  ceph-deploy osd prepare cephaio:sdd:/dev/sdb
  ceph-deploy osd prepare cephaio:sde:/dev/sdb
  ```

- Active c�c OSD v?a t?o ? tr�n
  ```sh
  ceph-deploy osd activate cephaio:/dev/sdc1:/dev/sdb1
  ceph-deploy osd activate cephaio:/dev/sdd1:/dev/sdb2
  ceph-deploy osd activate cephaio:/dev/sde1:/dev/sdb3
  ```

- Sau khi c?u h�nh c�c OSD xong, ki?m tra xem c�c ph�n v�ng b?ng l?nh `sudo lsblk`, n?u th�nh c�ng, k?t qu? nhu sau
  ```sh
  [ceph-deploy@cephaio cluster-ceph]$ lsblk
  NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
  sda               8:0    0   60G  0 disk
  +-sda1            8:1    0  500M  0 part /boot
  +-sda2            8:2    0 59.5G  0 part
    +-centos-root 253:0    0 35.9G  0 lvm  /
    +-centos-swap 253:1    0    6G  0 lvm  [SWAP]
    +-centos-home 253:2    0 17.5G  0 lvm  /home
  sdb               8:16   0   50G  0 disk
  +-sdb1            8:17   0  7.8G  0 part
  +-sdb2            8:18   0  7.8G  0 part
  +-sdb3            8:19   0  7.8G  0 part
  sdc               8:32   0   50G  0 disk
  +-sdc1            8:33   0   50G  0 part /var/lib/ceph/osd/ceph-0
  sdd               8:48   0   50G  0 disk
  +-sdd1            8:49   0   50G  0 part /var/lib/ceph/osd/ceph-1
  sde               8:64   0   50G  0 disk
  +-sde1            8:65   0   50G  0 part /var/lib/ceph/osd/ceph-2
  sr0              11:0    1  603M  0 rom
  [ceph-deploy@cephaio cluster-ceph]$
  ```

- T?o file config v� key
  ```sh
  ceph-deploy admin cephaio
  ```

- Ph�n quy?n cho file `/etc/ceph/ceph.client.admin.keyring`
  ```sh
  sudo chmod +r /etc/ceph/ceph.client.admin.keyring
  ```
  
- Ki?m tra tr?ng th�i c?a CEPH sau khi c�i
  ```sh
  ceph -s
  ```  
  
  - K?t c?a l?nh `ceph -s`
    ```sh
    [ceph-deploy@cephaio cluster-ceph]$   ceph -s
      cluster ae46be36-dee3-4bb9-9448-91aa148b301e
       health HEALTH_OK
       monmap e1: 1 mons at {cephaio=10.10.10.71:6789/0}
              election epoch 3, quorum 0 cephaio
       osdmap e15: 3 osds: 3 up, 3 in
              flags sortbitwise,require_jewel_osds
        pgmap v34: 64 pgs, 1 pools, 0 bytes data, 0 objects
              100 MB used, 149 GB / 149 GB avail
                    64 active+clean
  ```
  
- Ki?m tra c�c OSD b?ng l?nh `ceph osd tree`, k?t qu? nhu sau:
  ```sh
  [ceph-deploy@cephaio cluster-ceph]$ ceph osd tree
  ID WEIGHT  TYPE NAME        UP/DOWN REWEIGHT PRIMARY-AFFINITY
  -1 0.14639 root default
  -2 0.14639     host cephaio
   0 0.04880         osd.0         up  1.00000          1.00000
   1 0.04880         osd.1         up  1.00000          1.00000
   2 0.04880         osd.2         up  1.00000          1.00000
  ```
  
- Ki?m tra b?ng l?nh `ceph health`, k?t qu? nhu sau l� ok.
  ```sh
  [ceph-deploy@cephaio cluster-ceph]$ ceph health
  HEALTH_OK
  ```

## 6. C?u h�nh ceph d? client s? d?ng
### 6.1. C?u h�nh client -  CentOS 7.x 64 bit
- Th?c hi?n map v� mount c�c rbd cho client l� CentOS 7.x

#### Bu?c 1: Chu?n b? tr�n client 
- Login v�o m�y ch? v� chuy?n sang quy?n `root`
  ```sh
  su -
  ```

- Update c�c g�i cho m�y ch? 
  ```sh
  yum update -y
  ```

- �?t hostname cho m�y c�i CentOS Client1
  ```sh
  hostnamectl set-hostname centos7client1  
  ```
- Thi?t l?p IP cho m�y CEPH AIO
  ```sh
  echo "Setup IP  eno16777728"
  nmcli c modify eno16777728 ipv4.addresses 10.10.10.51/24
  nmcli c modify eno16777728 ipv4.method manual
  nmcli con mod eno16777728 connection.autoconnect yes


  echo "Setup IP  eno33554952"
  nmcli c modify eno33554952 ipv4.addresses 172.16.69.51/24
  nmcli c modify eno33554952 ipv4.gateway 172.16.69.1
  nmcli c modify eno33554952 ipv4.dns 8.8.8.8
  nmcli c modify eno33554952 ipv4.method manual
  nmcli con mod eno16777728 connection.autoconnect yes
  ```
  
- C?u h�nh c�c th�nh ph?n m?ng co b?n
  ```sh
  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  ```

- V� hi?u h�a Selinux
  ```sh
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  ```

- S?a file host 
  ```sh
  echo "10.10.10.71 cephaio" >> /etc/hosts
  echo "10.10.10.51 centos7client1" >> /etc/hosts
  ```

- Kh?i d?ng l?i m�y ch? sau khi c?u h�nh co b?n.
  ```sh
  init 6
  ```
 
- �ang nh?p l?i b?ng quy?n `root` sau khi m�y ch? reboot xong.

- Khai b�o repos cho CEPH 
  ```sh
  sudo yum install -y yum-utils
  sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ 
  sudo yum install --nogpgcheck -y epel-release 
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 
  sudo rm /etc/yum.repos.d/dl.fedoraproject.org*
  ```
   
  ```sh
  cat << EOF > /etc/yum.repos.d/ceph-deploy.repo
  [Ceph-noarch]
  name=Ceph noarch packages
  baseurl=http://download.ceph.com/rpm-jewel/el7/noarch
  enabled=1
  gpgcheck=1
  type=rpm-md
  gpgkey=https://download.ceph.com/keys/release.asc
  priority=1
  EOF
  ```

- Update sau khi khai b�o repo
  ```sh
  sudo yum -y update
  ```
  
- T?o user `ceph-deploy`
  ```sh
  sudo useradd -d /home/ceph-deploy -m ceph-deploy
  ```  
  
- �?t m?t kh?u cho user `ceph-deploy`
  ```sh
  sudo passwd ceph-deploy
  ```
  
- Ph�n quy?n cho user `ceph`
  ```sh
  echo "ceph-deploy ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
  chmod 0440 /etc/sudoers.d/ceph-deploy

  sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
  ```

#### Bu?c 2: �?ng tr�n node CEPH-AIO th?c hi?n c�c l?nh du?i.
- Login v�o m�y ch? CEPH AIO v� th?c hi?n c�c l?nh du?i
  - Chuy?n sang t�i kho?n `root`
    ```sh
    su -
    ```
  - Khai b�o th�m host c?a client 
    ```sh
    echo "10.10.10.51 centos7client1" >> /etc/hosts
    ```
    
  - Chuy?n sang t�i kho?n `ceph-deploy` d? th?c hi?n c�i d?t
    ```sh
    sudo su - ceph-deploy
    
    cd cluster-ceph
    ```
    
  - Copy ssh key d� t?o tru?c d� sang client, g� `yes` v� nh?p m?t kh?u c?a user `ceph-deploy` ph�a client d� t?o tru?c d�.
    ```sh
    ssh-copy-id ceph-deploy@centos7client1
    ```
  
- Th?c hi?n copy file config cho ceph v� key sang client
  ```sh
  ceph-deploy install centos7client1 
  ```
  
  - Sau khi k?t th�c qu� tr�nh c�i d?t cho client, n?u th�nh c�ng s? c� b�o k?t qu? nhu sau ? m�n h�nh.
    ```sh
    [centos7client1][DEBUG ] Complete!
    [centos7client1][INFO  ] Running command: sudo ceph --version
    [centos7client1][DEBUG ] ceph version 10.2.7 (50e863e0f4bc8f4b9e31156de690d765af245185)
    ```
  - Ti?p t?c th?c hi?n l?nh d? copy c�c file c?n thi?t t? node CEPH-AIO sang client
    ```sh
    ceph-deploy admin centos7client1
    ```   
  - Th?c hi?n xong l?nh tr�n, ceph-deploy s? copy c�c file c?n thi?t v�o thu m?c `/etc/ceph` c?a client. Chuy?n sang client d? th?c hi?n ti?p c�c thao t�c. 
  
#### Bu?c 3: Th?c hi?n c�c thao t�c d? s? d?ng rbd tr�n Client.
- �ang nh?p v�o t�i kho?n `root` c?a client (Trong ph?n n�y client l� CentOS 7)
- Th?c hi?n vi?c ki?m tra c�c g�i `ceph` d� du?c c�i b?ng l?nh `rpm -qa | grep ceph`
  ```sh
  [root@centos7client1 yum.repos.d]# rpm -qa | grep ceph
  python-cephfs-10.2.7-0.el7.x86_64
  ceph-base-10.2.7-0.el7.x86_64
  ceph-selinux-10.2.7-0.el7.x86_64
  ceph-osd-10.2.7-0.el7.x86_64
  ceph-mds-10.2.7-0.el7.x86_64
  ceph-radosgw-10.2.7-0.el7.x86_64
  libcephfs1-10.2.7-0.el7.x86_64
  ceph-common-10.2.7-0.el7.x86_64
  ceph-mon-10.2.7-0.el7.x86_64
  ceph-10.2.7-0.el7.x86_64
  ceph-release-1-1.el7.noarch
  ```

- K�ch ho?t rbdmap d? kh?i d?ng c�ng OS.
  ```sh
  [root@centos7client1 ceph]# systemctl enable rbdmap
  Created symlink from /etc/systemd/system/multi-user.target.wants/rbdmap.service to /usr/lib/systemd/system/rbdmap.service.
  ```
  
- T?o 1 RBD c� dung lu?ng 10Gb
  ```sh
  rbd create disk02 --size 10240
  ```
  - C� th? ki?m tra l?i k?t qu? t?o b?ng l?nh
    ```sh
    rbd ls -l
    ```
 
- Ch?y l?nh du?i d? fix l?i `RBD image feature set mismatch. You can disable features unsupported by the kernel with "rbd feature disable".` ? b?n  CEPH Jewel. Luu � t? kh�a `disk01` trong l?nh, n� l� t�n image c?a rbd du?c t?o.
  ```sh
  rbd feature disable rbd/disk01 fast-diff,object-map,exclusive-lock,deep-flatten
  ```

  
- Th?c hi?n map rbd v?a t?o 
  ```sh
  sudo rbd map disk01
  ```
  - Ki?m tra l?i k?t qu? map b?ng l?nh du?i
    ```sh
    rbd showmapped 
    ```
  
- Th?c hi?n format disk v?a du?c map
  ```sh
  sudo mkfs.xfs /dev/rbd0
  ```
  
- Th?c hi?n mount disk v?a du?c format d? s? d?ng (mount v�o thu m?c `mnt` c?a client)
  ```sh
  sudo mount /dev/rbd0 /mnt
  ```

- Ki?m tra l?i vi?c mount d� th�nh c�ng hay chua b?ng m?t trong c�c l?nh du?i
  ```sh
  df -hT
  ```

  ```sh
  lsblk
  ```
- T?o th? 1 file 5GB v�o thu m?c `/mnt` b?ng l?nh `dd`. L?nh n�y th?c hi?n tr�n client.
  ```sh
  cd /mnt 
  
  dd if=/dev/zero of=test bs=1M count=5000
  ```
  - N?u mu?n quan s�t qu� tr�nh ghi d?c tr�n server CEPH-AIO th� th?c hi?n l?nh `ceph -w` 

- M?c d?nh khi kh?i d?ng l?i th� vi?c map rbd s? b? m?t, x? l� nhu sau:
  - M? file /etc/ceph/rbdmap v� th�m d�ng du?i
    ```sh
    rbd/disk01   id=admin,keyring=/etc/ceph/ceph.client.admin.keyring
    ```
    - Luu � c?n khai b�o pool `rbd` v� t�n images l� `disk01` d� du?c khai b�o ? b�n tr�n.
    
  - S?a file `/etc/fstab` d? vi?c mount du?c th?c hi?n m?i khi kh?i d?ng l?i OS, th�m d�ng
    ```sh
    /dev/rbd0   /mnt  xfs defaults,noatime,_netdev        0       0
    ```
    
  - Trong qu� tr�nh lab v?i client l� ubuntu v� centos t�i g?p hi?n tu?ng kh?i d?ng l?i Client 2 l?n th� m?i dang nh?p du?c, chua hi?u t?i sao l?i b? t�nh tr?ng nhu v?y.

### 6.2. C?u h�nh client - Ubuntu Server 14.04 64 bit
- Bu?c n�y s? hu?ng d?n s? d?ng RBD c?a CEPH d? cung c?p cho c�c Client

#### Bu?c 1: Chu?n b? tr�n Client 

- Login v�o m�y ch? client v� chuy?n sang quy?n `root`
  ```sh
  su -
  ```

- C?u h�nh IP cho c�c NICs theo IP Planning
  ```sh
  cp /etc/network/interfaces  /etc/network/interfaces.orig
  
  
  cat << EOF > /etc/network/interfaces
  # This file describes the network interfaces available on your system
  # and how to activate them. For more information, see interfaces(5).

  # The loopback network interface
  auto lo
  iface lo inet loopback

  # The primary network interface
  auto eth0
  iface eth0 inet static
  address 10.10.10.52
  netmask 255.255.255.0

  auto eth1
  iface eth1 inet static
  address 172.16.69.52
  gateway 172.16.69.1
  netmask 255.255.255.0
  dns-nameservers 8.8.8.8
  EOF
  ```

- Thi?t l?p hostname
  ```sh
  echo "ubuntuclient2" > /etc/hostname
  hostname -F /etc/hostname
  ```
- S?a file host 
  ```sh
  echo "10.10.10.71 cephaio" >> /etc/hosts
  echo "10.10.10.52 ubuntuclient2" >> /etc/hosts
  ```
- Khai b�o Repo cho CEPH d?i v?i Ubuntu Server 14.04
  ```sh
  wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
  echo deb http://download.ceph.com/debian-jewel/ trusty main | sudo tee /etc/apt/sources.list.d/ceph.list
  ```
- Th?c hi?n update sau khi khai b�o repos v� kh?i d?ng l?i
  ```sh
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && init 6
  ```

- C�i d?t c�c g�i ceph ph�a client
  ```sh
  sudo apt-get install -y python-rbd ceph-common
  ```

- T?o user `ceph-deploy` d? s? d?ng cho vi?c c�i d?t cho CEPH.
  ```sh
  sudo useradd -m -s /bin/bash ceph-deploy
  ```

- �?t m?t m?u cho user `ceph-deploy`  
  ```sh
  sudo passwd ceph-deploy
  ```

- Ph�n quy?n cho user `ceph-deploy`
  ```sh
  echo "ceph-deploy ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
  sudo chmod 0440 /etc/sudoers.d/ceph-deploy
  ```

#### Bu?c 2: Chu?n b? tr�n Server CEPH 

- Login v�o m�y ch? CEPH AIO v� th?c hi?n c�c l?nh du?i
  - Khai b�o th�m host c?a client 
    ```sh
    echo "10.10.10.52 ubuntuclient2" >> /etc/hosts
    ```
    
  - Chuy?n sang t�i kho?n `ceph-deploy` d? th?c hi?n c�i d?t
    ```sh
    sudo su - ceph-deploy
    
    cd cluster-ceph
    ```
    
  - Copy ssh key d� t?o tru?c d� sang client, g� `yes` v� nh?p m?t kh?u c?a user `ceph-deploy` ph�a client d� t?o tru?c d�.
    ```sh
    ssh-copy-id ceph-deploy@ubuntuclient2
    ```
  
- Th?c hi?n copy file config cho ceph v� key sang client
```sh
ceph-deploy admin ubuntuclient2
```

#### Bu?c 3: T?o c�c RBD tr�n client 
- Login v�o m� h�nh c?a m�y client d? th?c hi?n c�c bu?c ti?p theo nhu sau:
- Chuy?n sang quy?n `root`
  ```sh
  su -
  ```
- Ph�n quy?n cho file `/etc/ceph/ceph.client.admin.keyring` v?a du?c copy sang ? tr�n
  ```sh
  sudo chmod +r /etc/ceph/ceph.client.admin.keyring
  ```

- Ki?m tra tr?ng th�i c?a CEPH t? client
  ```sh
  ceph -s
  ```
  - K?t qu? l�:
    ```sh
    root@ubuntuclient2:/etc/ceph# ceph -s
        cluster 2406781c-afdf-40c5-83a4-3ae49b2a3dea
         health HEALTH_OK
         monmap e1: 1 mons at {cephaio=10.10.10.71:6789/0}
                election epoch 4, quorum 0 cephaio
         osdmap e24: 3 osds: 3 up, 3 in
                flags sortbitwise,require_jewel_osds
          pgmap v3484: 64 pgs, 1 pools, 0 bytes data, 1 objects
                101 MB used, 149 GB / 149 GB avail
                      64 active+clean
    ```

- Kh?i d?ng rbdmap c�ng OS
  ```sh
  sudo update-rc.d rbdmap defaults
  ```

- C�i d?t th�m g�i `xfsprogs` d? c� th? s? d?ng l?nh `mkfs.xfs`
  ```sh
  sudo apt-get install xfsprogs
  ```
- T?o 1 RBD c� dung lu?ng 10Gb
  ```sh
  rbd create disk02 --size 10240
  ```
  - C� th? ki?m tra l?i k?t qu? t?o b?ng l?nh
    ```sh
    rbd ls -l
    ```
 
- Ch?y l?nh du?i d? fix l?i `RBD image feature set mismatch. You can disable features unsupported by the kernel with "rbd feature disable".` ? b?n  CEPH Jewel. Luu � t? kh�a `disk02` trong l?nh, n� l� t�n image c?a rbd du?c t?o.
  ```sh
  rbd feature disable rbd/disk02 fast-diff,object-map,exclusive-lock,deep-flatten
  ```

  
- Th?c hi?n map rbd v?a t?o 
  ```sh
  sudo rbd map disk02 
  ```
  - Ki?m tra l?i k?t qu? map b?ng l?nh du?i
    ```sh
    rbd showmapped 
    ```
  
- Th?c hi?n format disk v?a du?c map
  ```sh
  sudo mkfs.xfs /dev/rbd1
  ```
  
- Th?c hi?n mount disk v?a du?c format d? s? d?ng (mount v�o thu m?c `mnt` c?a client)
  ```sh
  sudo mount /dev/rbd1 /mnt
  ```

- Ki?m tra l?i vi?c mount d� th�nh c�ng hay chua b?ng m?t trong c�c l?nh du?i
  ```sh
  df -hT
  ```

  ```sh
  lsblk
  ```
- T?o th? 1 file 5GB v�o thu m?c `/mnt` b?ng l?nh `dd`. L?nh n�y th?c hi?n tr�n client.
  ```sh
  cd /mnt 
  
  dd if=/dev/zero of=test bs=1M count=5000
  ```
  - N?u mu?n quan s�t qu� tr�nh ghi d?c tr�n server CEPH-AIO th� th?c hi?n l?nh `ceph -w` 

- M?c d?nh khi kh?i d?ng l?i th� vi?c map rbd s? b? m?t, x? l� nhu sau:
  - M? file /etc/ceph/rbdmap v� th�m d�ng du?i
    ```sh
    rbd/disk02   id=admin,keyring=/etc/ceph/ceph.client.admin.keyring
    ```
    - Luu � c?n khai b�o pool `rbd` v� t�n images l� `disk01` d� du?c khai b�o ? b�n tr�n.
    
  - S?a file `/etc/fstab` d? vi?c mount du?c th?c hi?n m?i khi kh?i d?ng l?i OS, th�m d�ng
    ```sh
    /dev/rbd1   /mnt  xfs defaults,noatime,_netdev        0       0
    ```
    
  - Trong qu� tr�nh lab v?i client l� ubuntu t�i g?p hi?n tu?ng kh?i d?ng l?i Client 2 l?n th� m?i dang nh?p du?c, chua hi?u t?i sao l?i b? t�nh tr?ng nhu v?y.

  
### 7. C�c ghi ch� c?u h�nh client s? d?ng CEPH 

- File l?i khi th?c hi?n `map` c�c rbd, n?u ch?y xu?t hi?n l?i du?i
  ```sh
  ceph-deploy@client:~$ sudo rbd map disk01
  rbd: sysfs write failed
  RBD image feature set mismatch. You can disable features unsupported by the kernel with "rbd feature disable".
  In some cases useful info is found in syslog - try "dmesg | tail" or so.
  rbd: map failed: (6) No such device or address
  ```
  
  - Th� th?c hi?n
    ```sh
    rbd feature disable rbd/disk01 fast-diff,object-map,exclusive-lock,deep-flatten
    ```
    - Luu � t? kh�a `disk02` trong l?nh, n� l� t�n image c?a rbd du?c t?o.
    
- N?u khi th?c hi?n format ph�n v�ng RBD tr�n client`sudo: mkfs.xfs: command not found`, th� c?n c�i d?t g�i d? s? d?ng l?nh `mkfs.xfs`
  ```sh
  sudo apt-get install xfsprogs
  ```  

- L?nh d? xem thu?c t�nh c?a c�c lo?i disk trong linux
  ```sh
  blkid
  ```
  
- L?nh xem c�c pool trong CEPH
  ``` 
  root@ubuntuclient2:~# ceph osd lspools
  0 rbd,
  ```  

