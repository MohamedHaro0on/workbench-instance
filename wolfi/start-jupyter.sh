#!/bin/bash
set -e

echo "============================================"
echo "  GCP Workbench - Starting Jupyter"
echo "============================================"

echo "User: $(whoami)"
echo "Python: $(python3 --version 2>&1)"
echo "R: $(R --version 2>&1 | head -1)"

mkdir -p ~/.local/share/jupyter/kernels
mkdir -p ~/.local/share/jupyter/runtime
mkdir -p ~/.jupyter

echo ""
echo "Available kernels:"
jupyter kernelspec list

echo ""
echo "Starting JupyterLab on port 8080..."

exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --notebook-dir=/home/jupyter \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True