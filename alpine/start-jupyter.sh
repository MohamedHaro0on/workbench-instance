#!/bin/bash
# ============================================
# Jupyter Startup Script
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

# Log startup
echo "============================================"
echo "Starting Jupyter Lab"
echo "Python: $(python3 --version)"
echo "R: $(R --version | head -1)"
echo "Git: $(git --version)"
echo "gcloud: $(gcloud --version 2>/dev/null | head -1 || echo 'available')"
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