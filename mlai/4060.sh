#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install -y python3.14-full python3.12-full python3.11-full \
    python3-pip python3-venv python3-full python3-dev
sudo apt install -y build-essential g++ gcc g++-12 freeglut3-dev libx11-dev \
    libxmu-dev libxi-dev libglu1-mesa-dev libfreeimage-dev libglfw3-dev \
    libc++-dev gdb cmake linux-headers-$(uname -r) -y

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
#sudo apt install nvidia-dkms-580 nvidia-driver-580 -y
#sudo reboot
#nvidia-smi
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /"
sudo apt update
sudo apt install -y cuda-toolkit-13-0
sudo reboot
nvidia-smi