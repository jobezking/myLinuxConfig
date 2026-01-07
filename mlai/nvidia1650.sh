#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv python3-full python3-dev build-essential g++ gcc g++-12 freeglut3-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libfreeimage-dev libglfw3-dev linux-headers-$(uname -r) -y
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install nvidia-dkms-580 nvidia-driver-580 -y
sudo reboot
nvidia-smi
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /"
sudo apt update
sudo apt install -y cuda-toolkit-13-0 #everything else sudo apt install -y cuda-toolkit-13-1
#1650 only
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11-full
vim ~/.bashrc
#path for CUDA
export PATH=/usr/local/cuda-13.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# Path for TensorRT
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
source ~/.bashrc
sudo apt install -y libcudnn9-cuda-12 libcudnn9-dev-cuda-12
sudo apt install -y tensorrt
mkdir ~/pytorch && mkdir ~/tensorflow
cd ~/pytorch
python3.11 -m venv venv; source venv/bin/activate; cd $HOME  #everything else python3.12
pip install --upgrade pip setuptools wheel
pip install paddlepaddle-gpu paddleocr \
    torch torchvision torchaudio \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas \
    --extra-index-url https://download.pytorch.org/whl/cu130
pip-chill > $HOME/requirements_pytorch.txt
cd $HOME
cd ~/tensorflow
python3.11 -m venv venv; source venv/bin/activate; cd $HOME  #everything else python3.12
pip install --upgrade pip setuptools wheel
pip install tensorflow[and-cuda]==2.17.0 \
    tensorrt tensorrt_lean tensorrt_dispatch \
    paddlepaddle-gpu paddleocr \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas
pip-chill > $HOME/requirements_tensorflow.txt
cd $HOME
python3.11 -m venv venv; source venv/bin/activate; cd $HOME  #everything else python3.12
pip install --upgrade pip setuptools wheel
pip install tensorflow[and-cuda]==2.17.0 \
    tensorrt tensorrt_lean tensorrt_dispatch \
    paddlepaddle-gpu paddleocr \
    torch torchvision torchaudio \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas \
    --extra-index-url https://download.pytorch.org/whl/cu130
nvcc --version
pip-chill > requirements_tensorflow.txt
#EDA env only!
conda install -c conda-forge opencv-python ydata-profiling vaex
