#!/bin/bash
# ============================================
# Python/Jupyter Installation Script
# BUILD TIME: Uses official PyPI
# ============================================

set -e

echo "============================================"
echo "Installing Python packages (BUILD TIME)"
echo "Using: https://pypi.org/simple/ (Official)"
echo "============================================"

# Explicitly use official PyPI for build
export PIP_INDEX_URL=https://pypi.org/simple/
export PIP_TRUSTED_HOST=pypi.org

# Upgrade pip and build tools
pip install --upgrade pip
pip install --upgrade setuptools wheel

# ============================================
# CLIENT REQUIRED: virtualenv, pipenv
# ============================================
echo ">>> Installing virtualenv and pipenv..."
pip install virtualenv pipenv

# ============================================
# CLIENT REQUIRED: Jupyter kernel tools
# ============================================
echo ">>> Installing Jupyter ecosystem..."
pip install \
    jupyterlab \
    notebook \
    jupyter-server \
    jupyter-server-proxy \
    traitlets \
    ipykernel \
    ipywidgets \
    nbconvert

# ============================================
# CLIENT REQUIRED: Preinstalled Python packages
# ============================================
echo ">>> Installing Google Cloud packages..."
pip install \
    google-cloud-bigquery \
    google-cloud-bigquery-storage \
    db-dtypes

echo ">>> Installing data packages..."
pip install \
    pyarrow \
    pandas \
    numpy

# ============================================
# Security: Upgrade critical packages
# ============================================
echo ">>> Upgrading security-critical packages..."
pip install --upgrade \
    certifi \
    urllib3 \
    requests \
    cryptography

# ============================================
# Fix vendored wheel vulnerability
# ============================================
echo ">>> Applying setuptools security fixes..."
pip install --upgrade --force-reinstall setuptools

SETUPTOOLS_PATH=$(python3 -c "import setuptools; import os; print(os.path.dirname(setuptools.__file__))" 2>/dev/null || echo "")
if [ -n "$SETUPTOOLS_PATH" ] && [ -d "${SETUPTOOLS_PATH}/_vendor" ]; then
    rm -rf "${SETUPTOOLS_PATH}/_vendor/wheel"* 2>/dev/null || true
    echo "Removed vendored wheel from setuptools"
fi

# ============================================
# Verification
# ============================================
echo ""
echo "============================================"
echo "Verifying installed packages..."
echo "============================================"

python3 -c "import virtualenv; print('OK: virtualenv')"
python3 -c "import pipenv; print('OK: pipenv')"
python3 -c "import jupyterlab; print('OK: jupyterlab', jupyterlab.__version__)"
python3 -c "import notebook; print('OK: notebook')"
python3 -c "import google.cloud.bigquery; print('OK: google-cloud-bigquery')"
python3 -c "import google.cloud.bigquery_storage; print('OK: google-cloud-bigquery-storage')"
python3 -c "import db_dtypes; print('OK: db-dtypes')"
python3 -c "import pyarrow; print('OK: pyarrow', pyarrow.__version__)"
python3 -c "import pandas; print('OK: pandas', pandas.__version__)"

echo "============================================"
echo "Python packages installed successfully"
echo "============================================"