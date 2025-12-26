#!/bin/bash
sudo apt update
sudo apt install linux-headers-$(uname -r) build-essential -y
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo apt install -y ./cuda-keyring_1.1-1_all.deb; sudo apt update
#if needed. For Ubuntu desktop the proper driver is automatically installed
#https://developer.download.nvidia.com/compute/nvidia-driver/590.48.01/local_installers/nvidia-driver-local-repo-ubuntu2404-590.48.01_1.0-1_amd64.deb
# note: suda apt install -y cuda is sufficient. If this is done, perform ls -l /usr/bin/cuda* then skip to sudo apt install nvidia-gds -y
# for old GPUs like 1650
sudo apt install nvidia-driver-pinning-580
# for newer GPUs
sudo apt install nvidia-driver-pinning-590
sudo apt install -y nvidia-open
sudo apt --fix-broken install; sudo dpkg --configure -a; sudo apt update && sudo apt upgrade -y; sudo apt -y dist-upgrade
#sudo apt install -y cuda-drivers do not use
sudo shutdown -r now
sudo apt install -y nvidia-driver-assistant
#nvidia-driver-assistant
#nvidia-driver-assistant --install
#nvidia-driver-assistant --install --module-flavor closed
sudo systemctl restart nvidia-persistenced
cat /proc/driver/nvidia/version
# for old GPUs like 1650
#sudo apt-get -y install cuda-toolkit-12-9
# for newer GPUs
sudo apt-get -y install cuda-toolkit-13-1
#
sudo apt install nvidia-gds -y
sudo reboot
#$HOME/.bashrc
export PATH=${PATH}:/usr/local/cuda-13.1/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda-13.1/lib64
#
conda env create -f mlai_env.yml -n mlai_env
python -m ipykernel install --user --name=mlai_env --display-name "Python (mlai_env)"
conda activate mlai_env
