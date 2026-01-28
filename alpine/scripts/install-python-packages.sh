#!/bin/bash
# ============================================
# Python/Jupyter Installation Script
# ============================================

set -e

echo "============================================"
echo "Installing Python packages"
echo "============================================"

# Upgrade pip and build tools
pip install --no-cache-dir --upgrade pip
pip install --no-cache-dir --upgrade setuptools wheel

# Install Jupyter ecosystem
pip install --no-cache-dir \
    jupyterlab \
    notebook \
    jupyter-server \
    jupyter-server-proxy \
    traitlets \
    ipykernel \
    ipywidgets \
    nbconvert

# Fix vendored wheel vulnerability in setuptools
pip install --no-cache-dir --upgrade --force-reinstall setuptools

SETUPTOOLS_PATH=$(python3 -c "import setuptools; import os; print(os.path.dirname(setuptools.__file__))")
if [ -d "${SETUPTOOLS_PATH}/_vendor" ]; then
    rm -rf "${SETUPTOOLS_PATH}/_vendor/wheel"* 2>/dev/null || true
    echo "Removed vendored wheel from setuptools"
fi

echo "============================================"
echo "Python packages installed successfully"
echo "============================================"