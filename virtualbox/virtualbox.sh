echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian noble contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo gpg --dearmor -o /usr/share/keyrings/vbox.gpg
echo "deb [signed-by=/usr/share/keyrings/vbox.gpg] https://download.virtualbox.org/virtualbox/debian noble contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

sudo apt update
sudo apt install virtualbox-7.0 virtualbox-guest-additions-iso -y

lsmod | grep vbox
if needed:
sudo /sbin/vboxconfig

### Install Vagrant
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant -y

Mount Guest Additions Inside the VM
Once VirtualBox is installed, attach the ISO to the VM to install Guest Additions.

Guest additions Commands (inside VM):

sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
sudo usermod -aG vboxsf $USER
sudo reboot

or the slow way
Mount ISO: sudo mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt

Run installer: sudo /mnt/VBoxLinuxAdditions.run

Reboot VM: sudo reboot

The correct codename for Ubuntu 24.04 is noble, so the repo line must use noble contrib.

Guest Additions must be installed inside the VM, not on the host.

If you use headless servers, VirtualBox still installs fine, but Guest Additions features like clipboard and display resizing require X11 inside the VM.