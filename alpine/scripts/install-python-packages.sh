#!/bin/bash
# ============================================
# Python/Jupyter Installation Script
# BUILD TIME: Uses official PyPI
# SECURITY: Installs patched versions
# ============================================

set -e

echo "============================================"
echo "Installing Python packages (BUILD TIME)"
echo "Using: https://pypi.org/simple/ (Official)"
echo "============================================"

# Explicitly use official PyPI for build
export PIP_INDEX_URL=https://pypi.org/simple/
export PIP_TRUSTED_HOST=pypi.org

# ============================================
# SECURITY FIX: Upgrade pip to 26.0+ (CVE-2026-1703)
# ============================================
echo ">>> SECURITY: Upgrading pip to fix CVE-2026-1703..."
pip install --upgrade "pip>=26.0"

# Verify pip version
PIP_VERSION=$(pip --version | awk '{print $2}')
echo ">>> pip version: ${PIP_VERSION}"

# ============================================
# SECURITY FIX: Upgrade setuptools to 78.1.1+ (CVE-2025-47273)
# ============================================
echo ">>> SECURITY: Upgrading setuptools to fix CVE-2025-47273..."
pip install --upgrade "setuptools>=78.1.1"

# ============================================
# SECURITY FIX: Upgrade wheel to 0.46.2+ (CVE-2026-24049)
# ============================================
echo ">>> SECURITY: Upgrading wheel to fix CVE-2026-24049..."
pip install --upgrade "wheel>=0.46.2"

# Verify versions
echo ">>> Verifying security package versions..."
pip show setuptools | grep -E "^(Name|Version):"
pip show wheel | grep -E "^(Name|Version):"

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
# SECURITY: Final verification and cleanup
# ============================================
echo ">>> Final security verification..."

# Ensure pip, setuptools, wheel are at secure versions
pip install --upgrade "pip>=26.0" "setuptools>=78.1.1" "wheel>=0.46.2"

# Remove vendored wheel from setuptools (additional security measure)
echo ">>> Applying setuptools security fixes..."
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

echo "=== SECURITY PACKAGE VERSIONS ==="
pip --version
pip show setuptools | grep -E "^Version:"
pip show wheel | grep -E "^Version:"

echo ""
echo "=== FUNCTIONAL PACKAGES ==="
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