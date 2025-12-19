#initial install
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu focal universe"    #for netbeans
sudo add-apt-repository ppa:deadsnakes/ppa  #Python repo 
sudo apt install -y wget curl ssh gnupg software-properties-common gpg libfuse2 gftp tmux apt-transport-https ca-certificates lsb-release \
texlive-xetex texlive-fonts-recommended texlive-plain-generic sqlite3 libsqlite3-dev snapd snapd-xdg-open htop okular vainfo \
build-essential cmake gdb manpages-dev tree
# Remove Thunderbird and Rhythmbox
sudo snap remove --purge thunderbird; sudo apt-get remove --purge 'thunderbird*'; sudo apt-get --purge remove rhythmbox
sudo apt-get autoremove -y; sudo apt-get clean
wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb
sudo apt install ./synaptics-repository-keyring.deb -y
rm synaptics-repository-keyring.deb
# Add repos for Docker CE
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
#Intellij
#https://www.jetbrains.com/toolbox-app/download/download-thanks.html?platform=linux
cd $HOME/Downloads
wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.28.43.tar.gz
tar -xvzf jetbrains-toolbox-*.tar.gz
cd jetbrains-toolbox-* #will need to do auto-complete or ls to get exact directory name
cd bin
./jetbrains-toolbox 
#
#Microsoft Visual Studio repo
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg  
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
rm -f packages.microsoft.gpg
sudo apt update

# for development
sudo snap install termius-app steam
#sudo snap install pycharm-community --classic
sudo apt install -y code git-all gh konsole wget nano vim gnome-console gnome-text-editor thunar \
python3 python3-pip python3-virtualenv python3-dev libssl-dev libffi-dev net-tools \
python3-venv software-properties-common docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose \
vlc filezilla default-jdk default-jre netbeans golang-go python3.14-full kate gedit \
microsoft-edge-stable obs-studio kdenlive gnome-boxes displaylink-driver
###
git config --global user.name "My Name" && \
git config --global user.email "myemail@example.com" && \
git config --global core.editor "kate" && \
git config --global credential.helper "" && \
git config --global core.autocrlf true

###
#Nvidia only
sudo ubuntu-drivers install; sudo apt install -y nvidia-cuda-toolkit; sudo shutdown -r now
# ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 -vf "scale_cuda=1920:1080" -c:v h264_nvenc -preset fast -b:v 8M -c:a copy output.mp4

###
#AMD RDNA GPUs only
cd $HOME; sudo apt update && sudo apt upgrade -y
# Add AMD ROCm GPG key
wget https://repo.radeon.com/rocm/rocm.gpg.key
sudo mv rocm.gpg.key /etc/apt/trusted.gpg.d/
# Add ROCm repo for Ubuntu 24.04
wget https://repo.radeon.com/amdgpu-install/7.1.1/ubuntu/noble/amdgpu-install_7.1.1.70101-1_all.deb
sudo apt install ./amdgpu-install_7.1.1.70101-1_all.deb radeontop -y 
sudo apt update
sudo amdgpu-install --usecase=graphics,rocm,hiplibsdk --no-dkms
sudo usermod -a -G render,video $USER; sudo shutdown -r now
#
#Anaconda access  https://repo.anaconda.com/archive and replace below with latest Anaconda3-*-Linux-x86_64.sh
curl -O https://repo.anaconda.com/archive/Anaconda3-2025.12-1-Linux-x86_64.sh
    #after running command below, choose /opt/anaconda3 as target directory
sudo sh Anaconda3*
#once done perform below
sudo chown -R $USER:$USER /opt/anaconda3
cd /opt/anaconda3/bin
./conda init
#Try to exit shell and get back in. above should update /home/username/.bashrc with below
#echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.bashrc
#echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.profile 
#sudo shutdown -r now
conda update -n base -c defaults conda
conda update -n base -c conda-forge conda
conda update conda && conda update --all
conda install python=3.14
conda install nodejs
conda install -c conda-forge jupyterlab ipywidgets ipympl
conda install nb_conda_kernels
conda create --name main_env python=3.14
conda activate main_env
wget https://raw.githubusercontent.com/jobezking/learn_flask/refs/heads/main/requirements.txt
pip3 install -r requirements.txt
pip3 install ipykernel xgboost prospector setuptools
python -m ipykernel install --user --name=main_env --display-name "Python (main_env)"
conda deactivate
echo 'conda activate main_env' >> ~/.bashrc
echo 'conda activate main_env' >> ~/.profile
#Nvidia only part 2: PyTorch and TensorFlow
conda create --name ml_env python=3.11
conda activate ml_env
#obtain requirements.txt from https://github.com/jobezking/learn_flask
pip3 install -r requirements.txt
python -m pip install --upgrade pip setuptools wheel prospector
python -c "import ctypes, sys; print('ok')" && echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
pip install torch torchvision torchaudio 
pip install torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install tensorflow
pip install nvidia-cuda-runtime-cu12 nvidia-cuda-cupti-cu12 nvidia-cublas-cu12 nvidia-cudnn-cu12 nvidia-cufft-cu12 nvidia-curand-cu12 nvidia-cusolver-cu12 nvidia-cusparse-cu12
pip install cupy-cuda12x
pip install jupyterlab ipykernel xgboost
python -m ipykernel install --user --name mlgpu --display-name "Python (mlgpu)"
python -m ipykernel install --user --name=ml_env --display-name "Python (ml_env)"
conda deactivate
#for Pycharm: Settings → Project → Python Interpreter → Add → Existing → point to ~/mlgpu/bin/python
#for Vscode, Select the “Python (mlgpu)” interpreter in the status bar
#or for both/either conda activate ml_env
conda deactivate

#AMD RDNA only part 2: Pytorch and TensorFlow
conda create -n ml_env python=3.11
conda activate ml_env
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
pip3 install tensorflow-rocm
echo 'export HSA_OVERRIDE_GFX_VERSION=10.3.0' >> ~/.bashrc
echo 'conda activate ml_env' >> ~/.bashrc
conda install -c conda-forge jupyterlab=4.5.0 nodejs=20 ipywidgets ipympl scikit-learn=1.8.0
conda deactivate
python -m ipykernel install --user --name=ml_env --display-name "Python (ml_env)"

# To install Spyder ( spyder-ide.org ) for Python development. Install in /opt/spyder-6 directory.
# To run: spyder (may require reboot to work from command line). To uninstall: sudo /opt/spyder-6/uninstall-spyder.sh 
sudo ls
wget https://github.com/spyder-ide/spyder/releases/latest/download/Spyder-Linux-x86_64.sh && sudo sh Spyder-Linux-x86_64.sh

sudo apt update && sudo apt upgrade -y --allow-downgrades && sudo apt dist-upgrade -y && sudo apt autoremove -y

#Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb; sudo apt update

#Chrome Remote Desktop. To avoid session conflicts, create a dedicated account. Do not configure Chrome Remote Desktop in a user account
sudo adduser crdp
sudo usermod -aG sudo crdp
su crdp
cd /home/crdp
sudo ls
echo "deb [arch=amd64] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/chrome-remote-desktop.list
sudo apt-get update
sudo apt install -y chrome-remote-desktop
#On another host using Chrome browser signed into account that you wish to use, access https://remotedesktop.google.com/headless
#and follow instructions
sudo systemctl status chrome-remote-desktop@$USER    #to see if service is running
#when logging in for the first time, DO NOT use the Default X Session. Pick the Ubuntu session.

#Replace Firefox Snap with repo version
sudo snap remove --purge firefox
sudo apt-get remove --purge 'firefox*'
sudo apt-get autoremove
sudo apt-get clean
#https://askubuntu.com/questions/1399383/how-to-install-firefox-as-a-traditional-deb-package-without-snap-in-ubuntu-22
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
#The fingerprint should be 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); print "\n"$0"\n"}'
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt-get update && sudo apt-get install firefox -y

#How to use LVM to add USBs, sdcards etc.

#Use diskparted etc. to format all disks
#Only insert the primary disk. Install Ubuntu 24 or higher using advanced LVM option. This will create an LVM volume using the boot disk.
#Insert all other disks. Format them as ext4 (internal Linux disk only) but do not mount them.
#Use sudo lvmdiskscan to verify that primary and other disks are recognized by LVM
#Use sudo pvs to see all lvm2 physical volumes, which at this point should be only the boot disk.
#Use sudo pvcreate device1 device 2 etc. for all the other disks that you wish to join with the boot disk (do not include boot disk) i.e. sudo pvcreate /dev/sdb /dev/mmcblk0p1
#Use sudo vgextend volgrp dev1 dev2 etc to add the new disks to the volume group i.e. sudo vgextend ubuntu-vg /dev/mmcblk0p1 /dev/sdb
#Now extend the logical volume to include all the space on the new disk. This will require identifying and using the filesystem name, not the group name so to obtain it run sudo df -h /home, sudo df -h /opt or similar. Get /dev/mapper/… result under Filesystem
#Expand logical volume to all available space in volume group with: sudo lvextend -l +100%FREE /dev/mapper/vg_cloud-LogVol00
#Use resizefs command to make it take effect: sudo resize2fs /dev/mapper/vg_cloud-LogVol0
#sudo lvextend -l +100%FREE /dev/mapper/vg_cloud-LogVol00 combines 9 and 10

References:
https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations 
https://www.digitalocean.com/community/tutorials/how-to-use-lvm-to-manage-storage-devices-on-ubuntu-18-04 
https://www.linuxtechi.com/extend-lvm-partitions/ 

#Notepad++ Linux version
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo shutdown -r now
sudo flatpak install flathub com.github.dail8859.NotepadNext

#Terraform repo
sudo ls
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update; sudo apt install -y terraform
