#!/bin/bash
conda env list
conda env remove --name pyt_e -y
#
conda deactivate; conda create -n py312c13 python=3.12 -c conda-forge -y; \
conda create -n tf312c13 python=3.12 -c conda-forge -y;

conda activate py312c13
pip install --upgrade pip setuptools wheel
conda install -c nvidia cuda-toolkit=13.0 -y
pip install paddlepaddle-gpu paddleocr \
    torch torchvision torchaudio \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas \
    --extra-index-url https://download.pytorch.org/whl/cu130
conda install -c conda-forge opencv ydata-profiling scikit-bio -y
conda env export > py312c13.yml
nvcc --version
conda deactivate

conda activate tf312c13
pip install --upgrade pip setuptools wheel
conda install -c nvidia cuda-toolkit=13.0 -y
pip install tensorflow[and-cuda]==2.20.0 \
    tensorrt tensorrt_lean tensorrt_dispatch \
    paddlepaddle-gpu paddleocr \
	pandas numpy scikit-learn scipy matplotlib matplotlib-inline seaborn xgboost \
	duckdb tinydb lancedb milvus-lite surrealdb flask python-dotenv flask-wtf \
	jupyter jupyterlab notebook ipython ipywidgets jupyterlab_widgets ipympl \
	sqlalchemy requests beautifulsoup4 pillow fsspec pandera pyyaml pip-chill tsfresh \
	dtale pyjanitor openpyxl statsmodels tqdm  itables geopandas
conda install -c conda-forge opencv ydata-profiling scikit-bio -y
conda env export > tf312c13.yml
nvcc --version
conda deactivate
