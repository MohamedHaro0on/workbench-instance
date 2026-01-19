#!/bin/bash
set -e

# Set environment
export HOME=/home/jupyter
export USER=jupyter
export PATH="/usr/local/python/bin:/usr/local/curl/bin:/usr/local/sqlite/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/python/lib:/usr/local/curl/lib:/usr/local/sqlite/lib:${LD_LIBRARY_PATH}"

# Create necessary directories
mkdir -p /home/jupyter/.local/share/jupyter/kernels
mkdir -p /home/jupyter/.cache
mkdir -p /home/jupyter/work

# Log startup info
echo "=== GCP Workbench Startup ==="
echo "Python: $(python3 --version)"
echo "Jupyter: $(jupyter --version | head -1)"
echo "R: $(R --version | head -1)"
echo "Curl: $(curl --version | head -1)"
echo "SQLite: $(sqlite3 --version)"
echo "=== Starting Jupyter Server on port 8080 ==="

# Start Jupyter server
exec /usr/local/python/bin/jupyter-lab \
    --config=/home/jupyter/.jupyter/jupyter_server_config.py \
    --no-browser \
    --ip=0.0.0.0 \
    --port=8080 \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.base_url='/'