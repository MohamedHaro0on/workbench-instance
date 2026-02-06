#!/bin/bash
# ============================================
# Jupyter Startup Script
# GCP Workbench - R 4.1.0 + Python
# ============================================

set -e

# Ensure directories exist with correct permissions
mkdir -p /home/jupyter/.jupyter
mkdir -p /home/jupyter/.local/share/jupyter/runtime
mkdir -p /home/jupyter/.local/share/jupyter/kernels
mkdir -p /home/jupyter/work
mkdir -p /home/jupyter/.config/gcloud

# Export environment
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-}"
export CLOUDSDK_CONFIG="/home/jupyter/.config/gcloud"
export HOME="/home/jupyter"

# Log startup
echo "============================================"
echo "Starting Jupyter Lab"
echo "============================================"
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Python: $(python3 --version 2>&1)"
echo "pip: $(pip --version 2>&1)"
echo "R: $(R --version 2>&1 | head -1)"
echo "Git: $(git --version 2>&1)"
echo "gcloud: $(gcloud --version 2>&1 | head -1 || echo 'available')"
echo "============================================"
echo "Installed Jupyter Kernels:"
jupyter kernelspec list 2>&1
echo "============================================"

# Verify R kernel is available
if jupyter kernelspec list 2>&1 | grep -q "ir"; then
    echo "R kernel: OK"
else
    echo "WARNING: R kernel not found!"
fi

# Verify Python kernel is available
if jupyter kernelspec list 2>&1 | grep -q "python3"; then
    echo "Python kernel: OK"
else
    echo "WARNING: Python kernel not found!"
fi

echo "============================================"
echo "Starting Jupyter Lab on port 8080..."
echo "============================================"

# Start Jupyter
exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --allow-root \
    --notebook-dir=/home/jupyter \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True