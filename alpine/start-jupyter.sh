#!/bin/bash
set -e

echo "============================================"
echo "  GCP Workbench - Starting Jupyter"
echo "============================================"
echo "User: $(whoami)"
echo "UID: $(id -u)"
echo "GID: $(id -g)"
echo "Home: $HOME"
echo "Python: $(python3 --version 2>&1)"
echo "R: $(R --version 2>&1 | head -1)"

# Ensure directories exist for current user
mkdir -p ~/.local/share/jupyter/kernels
mkdir -p ~/.local/share/jupyter/runtime
mkdir -p ~/.jupyter

# Copy config if running as root and config not present
if [ "$(id -u)" = "0" ] && [ ! -f /root/.jupyter/jupyter_server_config.py ]; then
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/ 2>/dev/null || true
fi

echo ""
echo "Available kernels:"
jupyter kernelspec list

echo ""
echo "Starting JupyterLab on port 8080..."
echo ""

exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --notebook-dir=/home/jupyter \
    --ServerApp.token="" \
    --ServerApp.password="" \
    --ServerApp.allow_origin="*" \
    --ServerApp.allow_remote_access=True \
    --ServerApp.allow_root=True \
    --allow-root