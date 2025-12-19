sudo apt update
sudo apt install nvidia-cuda-toolkit docker.io -y
sudo systemctl enable --now docker
# Add your user to the docker group to run without 'sudo'
sudo usermod -aG docker $USER

nvidia-smi
sudo ubuntu-drivers install
sudo reboot
# Create the environment
conda create -n ai_env python=3.11 -y

# Activate the environment
conda activate ai_env
pip install tensorflow[and-cuda]

conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia

# Data Processing and Visualization
conda install numpy pandas matplotlib pillow scikit-learn -y

# Image Processing (OpenCV)
conda install -c conda-forge opencv -y

# Web Framework (Flask)
conda install flask -y

# Helpers
conda install -c conda-forge pandas-stubs openpyxl seaborn scipy scikit-bio flask-wtf -y

#To reproduce the environment later:

conda env export > ai_env.yml


curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker

###checkai.py
import tensorflow as tf
import torch

print("TF GPU:", tf.config.list_physical_devices('GPU'))
print("PyTorch GPU:", torch.cuda.is_available())
print("Device Name:", torch.cuda.get_device_name(0))