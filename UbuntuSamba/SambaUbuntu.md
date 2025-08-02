\# [https://ubuntu.com/tutorials/install-and-configure-samba\#2-installing-samba](https://ubuntu.com/tutorials/install-and-configure-samba#2-installing-samba)  
\# [https://phoenixnap.com/kb/ubuntu-samba](https://phoenixnap.com/kb/ubuntu-samba)  
\# [https://wiki.samba.org/index.php/Setting\_up\_Samba\_as\_a\_Standalone\_Server](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)   
\# [https://www.linuxfordevices.com/tutorials/linux/linux-samba](https://www.linuxfordevices.com/tutorials/linux/linux-samba) 

sudo apt update && sudo apt install \-y samba  
samba \-V  
sudo systemctl status smb  
sudo smbpasswd \-a username \# set to be same as logon with sudo access  
\#assume that /media folder exists with proper permissions  
sudo vim /etc/samba/smb.conf \#place below at bottom of file  
\[media\]  
    comment \= Samba on Ubuntu  
    path \= /media  
    read only \= no  
    browsable \= yes  
    inherit permissions \= yes  
\#\#\#  
sudo service smbd restart && sudo ufw allow samba

To map: //hostname/media  
Linux: smb://hostname/media