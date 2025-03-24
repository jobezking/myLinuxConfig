#for SMB mounts and to find mount point for USB drives
#https://linuxier.com/how-to-install-gnome-disks-utility-on-ubuntu/
sudo apt-get install cifs-utils gnome-disk-utility -y
sudo mkdir /media/mount1
sudo mkdir /media/mount2
sudo mkdir /media/mount3
sudo mkdir /media/mount4
sudo chmod 777 /media/mount1 #for CIFS 1.0
sudo chmod 777 /media/mount2 #for CIFS 2.0
sudo chmod 777 /media/mount3 #for USB 1
sudo chmod 777 /media/mount4 #for USB 2
#contents of fstab file begin
//192.168.1.75/public /media/mount1 cifs vers=1.0,file_mode=0777,username=username,password=password
//192.168.1.240/smbsha /media/mount2 cifs vers=2.0,file_mode=0777,username=username,password=password
/dev/sdb1 /media/mount3 ntfs rwx 0 0
/dev/sdc1 /media/mount4 ntfs rwx 0 0
#contents of fstab end
#verify fstab
sudo findmnt --verify
cp /etc/fstab /home/user/fstab
sudo findmnt -F /home/user/fstab --verify
#open second window and enter tail -f /var/log/syslog
sudo mount -a
