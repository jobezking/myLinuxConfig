#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install -y python3.14-full python3.12-full python3.11-full wget curl
sudo apt install -y python3-pip python3-venv python3-full python3-dev build-essential g++ gcc g++-12 freeglut3-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libfreeimage-dev libglfw3-dev linux-headers-$(uname -r) -y
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y nvidia-driver-assistant
#sudo apt install nvidia-dkms-580 nvidia-driver-580 -y
sudo nvidia-driver-assistant --install --module-flavor=closed
sudo reboot
nvidia-smi
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /"
sudo apt update
sudo apt install -y cuda-toolkit-13-0 #everything else sudo apt install -y cuda-toolkit-13-1
#path for CUDA
export PATH=/usr/local/cuda-13.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# Path for TensorRT
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
source ~/.bashrc
sudo apt install -y libcudnn9-cuda-13 libcudnn9-dev-cuda-13 tensorrt
#Anaconda access  https://repo.anaconda.com/archive and replace below with latest Anaconda3-*-Linux-x86_64.sh
curl -O https://repo.anaconda.com/archive/Anaconda3-2025.12-1-Linux-x86_64.sh
    #after running command below, choose /opt/anaconda3 as target directory
sudo sh Anaconda3*
#once done perform below
sudo chown -R $USER:$USER /opt/anaconda3
cd /opt/anaconda3/bin
./conda init
conda update -n base -c defaults conda
source ~/.bashrc
conda deactivate
conda create -n py311c129 python=3.11 -c conda-forge -y; \
conda create -n tf311c129 python=3.11 -c conda-forge -y; \
conda create -n ml311c129 python=3.11 -c conda-forge -y
conda activate py311c129 
pip install --upgrade pip setuptools wheel
conda install -c nvidia cuda-toolkit=12.9 -y
pip install paddlepaddle-gpu paddleocr \
    torch torchvision torchaudio \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas \
    --extra-index-url https://download.pytorch.org/whl/cu129
conda install -c conda-forge opencv ydata-profiling scikit-bio -y
conda env export > py311c129.yml
nvcc --version
conda deactivate
conda activate tf311c129
pip install --upgrade pip setuptools wheel
conda install -c nvidia cuda-toolkit=12.9 -y
pip install tensorflow[and-cuda]==2.17.0 \
    tensorrt tensorrt_lean tensorrt_dispatch \
    paddlepaddle-gpu paddleocr \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas
conda install -c conda-forge opencv ydata-profiling scikit-bio -y
conda env export > tf311c129.yml
nvcc --version
conda deactivate
conda activate ml311c129
pip install --upgrade pip setuptools wheel
conda install -c nvidia cuda-toolkit=12.9 -y
pip install tensorflow[and-cuda]==2.17.0 \
    tensorrt tensorrt_lean tensorrt_dispatch \
    paddlepaddle-gpu paddleocr \
    torch torchvision torchaudio \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas \
    --extra-index-url https://download.pytorch.org/whl/cu129
conda install -c conda-forge opencv ydata-profiling scikit-bio -y
conda env export > ml311c129.yml
nvcc --version
conda deactivate
# Add repos for Docker CE
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
# Add NVIDIA container toolkit repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
