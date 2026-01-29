#!/bin/bash
# ============================================
# Python/Jupyter Installation Script
# Includes all client-requested packages
# ============================================

set -e

echo "============================================"
echo "Installing Python packages"
echo "============================================"

# Upgrade pip and build tools to latest secure versions
pip install --no-cache-dir --upgrade pip
pip install --no-cache-dir --upgrade setuptools wheel

# Read packages from file if exists, otherwise use defaults
PACKAGES_FILE="/tmp/packages/python-packages.txt"

if [ -f "$PACKAGES_FILE" ]; then
    echo "Installing from packages file..."
    # Filter comments and empty lines
    grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | while read -r package; do
        echo "Installing: $package"
        pip install --no-cache-dir "$package" || echo "Warning: Failed to install $package"
    done
else
    echo "Installing default packages..."
    pip install --no-cache-dir \
        jupyterlab \
        notebook \
        jupyter-server \
        jupyter-server-proxy \
        traitlets \
        ipykernel \
        ipywidgets \
        nbconvert \
        google-cloud-bigquery \
        google-cloud-bigquery-storage \
        db-dtypes \
        pyarrow \
        pandas \
        numpy \
        virtualenv \
        pipenv
fi

# Fix vendored wheel vulnerability in setuptools (CVE mitigation)
echo "Applying setuptools security fixes..."
pip install --no-cache-dir --upgrade --force-reinstall setuptools

SETUPTOOLS_PATH=$(python3 -c "import setuptools; import os; print(os.path.dirname(setuptools.__file__))" 2>/dev/null || echo "")
if [ -n "$SETUPTOOLS_PATH" ] && [ -d "${SETUPTOOLS_PATH}/_vendor" ]; then
    rm -rf "${SETUPTOOLS_PATH}/_vendor/wheel"* 2>/dev/null || true
    echo "Removed vendored wheel from setuptools"
fi

# Upgrade security-critical packages to latest
echo "Upgrading security-critical packages..."
pip install --no-cache-dir --upgrade \
    certifi \
    urllib3 \
    requests \
    cryptography \
    pyOpenSSL

echo "============================================"
echo "Python packages installed successfully"
echo "============================================"