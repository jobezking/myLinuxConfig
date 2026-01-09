#!/bin/bash

# 1. CUDA 13.0 | Python 3.12 | TensorFlow
echo "Creating Environment 1: tf_cuda13..."
conda create -n tf_cuda13 python=3.12 -y
conda install -n tf_cuda13 -c nvidia cuda-toolkit=13.0 -y
conda run -n tf_cuda13 pip install tensorflow[and-cuda]

# 2. CUDA 12.6 | Python 3.11 | TensorFlow
echo "Creating Environment 2: tf_cuda126..."
conda create -n tf_cuda126 python=3.11 -y
conda install -n tf_cuda126 -c nvidia cuda-toolkit=12.6 -y
conda run -n tf_cuda126 pip install tensorflow[and-cuda]

# 3. CUDA 13.0 | Python 3.12 | PyTorch
echo "Creating Environment 3: torch_cuda13..."
conda create -n torch_cuda13 python=3.12 -y
conda install -n torch_cuda13 -c nvidia cuda-toolkit=13.0 -y
conda run -n torch_cuda13 pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# 4. CUDA 12.6 | Python 3.11 | PyTorch
echo "Creating Environment 4: torch_cuda126..."
conda create -n torch_cuda126 python=3.11 -y
conda install -n torch_cuda126 -c nvidia cuda-toolkit=12.6 -y
conda run -n torch_cuda126 pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

echo "------------------------------------------------"
echo "All environments created successfully!"
echo "Use 'conda env list' to see your new environments."
