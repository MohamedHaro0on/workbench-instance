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
echo "Python: $(python3 --version 2>&1)"
echo "R: $(R --version 2>&1 | head -1)"
echo "=== Starting Jupyter Server on port 8080 ==="

# Start Jupyter - use the existing workbench entrypoint if available
if [ -f /entrypoint.sh ]; then
    exec /entrypoint.sh
elif command -v jupyter-lab &> /dev/null; then
    exec jupyter-lab \
        --config=/home/jupyter/.jupyter/jupyter_server_config.py \
        --no-browser \
        --ip=0.0.0.0 \
        --port=8080 \
        --ServerApp.token='' \
        --ServerApp.password='' \
        --ServerApp.allow_origin='*'
else
    exec jupyter server \
        --config=/home/jupyter/.jupyter/jupyter_server_config.py \
        --no-browser \
        --ip=0.0.0.0 \
        --port=8080
fi
