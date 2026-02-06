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

export PIP_INDEX_URL=https://pypi.org/simple/
export PIP_TRUSTED_HOST=pypi.org

# ============================================
# SECURITY: Ensure secure versions are installed
# ============================================
echo ">>> SECURITY: Verifying secure package versions..."
pip install --upgrade "pip>=26.0"
pip install --upgrade "setuptools>=78.1.1"
pip install --upgrade "wheel>=0.46.2"
pip install --upgrade "cryptography>=44.0.1"

echo ">>> pip version: $(pip --version)"
echo ">>> setuptools version: $(pip show setuptools | grep Version)"
echo ">>> wheel version: $(pip show wheel | grep Version)"
echo ">>> cryptography version: $(pip show cryptography | grep Version)"

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
    "urllib3>=2.0" \
    "requests>=2.31"

# ============================================
# SECURITY: Final verification
# ============================================
echo ">>> Final security verification..."
pip install --upgrade "pip>=26.0" "setuptools>=78.1.1" "wheel>=0.46.2" "cryptography>=44.0.1"

# Remove vendored wheel from setuptools
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
echo "FINAL VERIFICATION"
echo "============================================"
echo "pip: $(pip --version)"
echo "setuptools: $(pip show setuptools | grep Version)"
echo "wheel: $(pip show wheel | grep Version)"
echo "cryptography: $(pip show cryptography | grep Version)"
echo "============================================"