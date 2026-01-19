#!/bin/bash
# GCP Workbench Jupyter Startup Script

set -e

echo "=========================================="
echo "Starting GCP Workbench Jupyter Server"
echo "=========================================="

# Environment info
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "Python: $(python3 --version)"
echo "R: $(R --version | head -1)"

# Ensure directories exist
mkdir -p /home/jupyter/.local/share/jupyter/kernels
mkdir -p /home/jupyter/.jupyter
mkdir -p /home/jupyter/work

# Verify R kernel is installed
echo "Checking Jupyter kernels..."
jupyter kernelspec list

# Start Jupyter Lab
echo "Starting JupyterLab on port 8080..."
exec jupyter lab \
    --config=/home/jupyter/.jupyter/jupyter_server_config.py \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --notebook-dir=/home/jupyter \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True