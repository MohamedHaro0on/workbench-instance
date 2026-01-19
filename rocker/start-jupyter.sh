#!/bin/bash
set -e

# Set environment
export HOME=/home/jupyter
export USER=jupyter

# Create necessary directories
mkdir -p /home/jupyter/.local/share/jupyter/kernels
mkdir -p /home/jupyter/.cache
mkdir -p /home/jupyter/work

# Log startup info
echo "=== GCP Workbench Startup ==="
echo "Python: $(python3 --version)"
echo "R: $(R --version | head -1)"
echo "Jupyter: $(jupyter --version | head -1)"
echo "=== Starting Jupyter Server on port 8080 ==="

# Start Jupyter Lab
exec jupyter-lab \
    --config=/home/jupyter/.jupyter/jupyter_server_config.py \
    --no-browser \
    --ip=0.0.0.0 \
    --port=8080 \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.base_url='/'