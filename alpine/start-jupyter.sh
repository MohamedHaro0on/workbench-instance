#!/bin/bash
# ============================================
# Jupyter Startup Script
# ============================================

set -e

# Ensure directories exist
mkdir -p /home/jupyter/.jupyter
mkdir -p /home/jupyter/.local/share/jupyter/runtime
mkdir -p /home/jupyter/work

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