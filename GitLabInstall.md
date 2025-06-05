GitLab  
[https://www.letscloud.io/community/how-to-install-and-configure-gitlab-on-ubuntu-20-04](https://www.letscloud.io/community/how-to-install-and-configure-gitlab-on-ubuntu-20-04)  
[https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-gitlab-on-ubuntu](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-gitlab-on-ubuntu)  
[https://www.linuxtechi.com/how-to-install-gitlab-on-ubuntu/](https://www.linuxtechi.com/how-to-install-gitlab-on-ubuntu/)  
[https://linuxize.com/post/how-to-install-and-configure-gitlab-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-and-configure-gitlab-on-ubuntu-18-04/)

1. sudo apt update && sudo apt upgrade \-y  
2. sudo debconf-set-selections \<\<\< "postfix postfix/mailname string $(hostname \-f)"  
3. sudo debconf-set-selections \<\<\< "postfix postfix/main\_mailer\_type string 'Internet Site'"  
4. sudo apt install ca-certificates curl openssh-server postfix tzdata perl \-y  
5. On Postfix configuration screen choose “Internet Site”  
6. curl \-sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash  
7. sudo EXTERNAL\_URL="[https://git-ubuntu.bosgame.pve.lan](http://git-ubuntu.bosgame.pve.lan)" apt install gitlab-ce \-y  
8. sudo ufw allow http && sudo ufw allow https && sudo ufw allow OpenSSH  
9. sudo vim /etc/gitlab/[gitlab.rb](http://gitlab.rb) \> update gitlab\_rails\['backup\_path'\] \= '/opt/gitlab\_backups'  
   1. letsencrypt\['enable'\] \= true  
   2. letsencrypt\['auto\_renew'\] \= true  
   3. letsencrypt\['auto\_renew\_hour'\] \= 5  
   4. letsencrypt\['auto\_renew\_day\_of\_month'\] \= "\*/6"  
10. sudo gitlab-ctl reconfigure  
11. sudo gitlab-rake gitlab:check  
12. crontab \-e  
13. 0 5 1 \* \* sudo gitlab-rake gitlab:backup:create  
14. sudo cat /etc/gitlab/initial\_root\_password  
15. Visit [https://git-ubuntu.bosgame.pve.lan](http://git-ubuntu.bosgame.pve.lan)  
16. Edit Profile \> User Settings \> Password  
17. Account \> change username from root to jeking

Adding SSH keys

1. Log into client and cd $HOME  
2. ssh-keygen  
3. cat \~/.ssh/id\_rsa.pub   
4. Copy output   
5. On Gitlab UI \> SSH Keys \> Add an SSH key  
6. Paste 4\. Into Key text box, give it a Title and click Add key button