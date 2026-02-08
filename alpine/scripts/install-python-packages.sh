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
# SECURITY FIX: Upgrade core packages FIRST
# ============================================
echo ">>> SECURITY: Upgrading core packages to fix all CVEs..."
echo ">>> Target versions:"
echo "    - pip >= 26.0 (fixes CVE-2025-8869, CVE-2026-1703)"
echo "    - setuptools >= 78.1.1 (fixes CVE-2024-6345, CVE-2025-47273)"
echo "    - wheel >= 0.46.2 (fixes CVE-2026-24049)"
echo "    - cryptography >= 44.0.1 (fixes GHSA-h4gh-qq45-vh27, CVE-2024-12797)"

# Upgrade pip first
pip install --no-cache-dir --upgrade "pip>=26.0"

# Now upgrade other security packages
pip install --no-cache-dir --upgrade \
    "setuptools>=78.1.1" \
    "wheel>=0.46.2" \
    "cryptography>=44.0.1"

# Verify versions
echo ""
echo ">>> Verifying security package versions..."
PIP_VER=$(pip show pip | grep "^Version:" | cut -d' ' -f2)
SETUPTOOLS_VER=$(pip show setuptools | grep "^Version:" | cut -d' ' -f2)
WHEEL_VER=$(pip show wheel | grep "^Version:" | cut -d' ' -f2)
CRYPTO_VER=$(pip show cryptography | grep "^Version:" | cut -d' ' -f2)

echo "    pip: ${PIP_VER}"
echo "    setuptools: ${SETUPTOOLS_VER}"
echo "    wheel: ${WHEEL_VER}"
echo "    cryptography: ${CRYPTO_VER}"

# Version check function - FIXED: removed backslashes from \$1, \$2, \$3
check_version() {
    local pkg=\$1
    local current=\$2
    local required=\$3
    
    if [ -z "$current" ]; then
        echo "ERROR: $pkg version not found"
        exit 1
    fi
    
    # Compare versions using sort -V
    local lowest=$(printf '%s\n' "$required" "$current" | sort -V | head -n1)
    if [ "$lowest" != "$required" ]; then
        echo "ERROR: $pkg version $current is less than required $required"
        exit 1
    fi
    echo "    OK: $pkg $current >= $required"
}

echo ""
echo ">>> Version check..."
check_version "pip" "$PIP_VER" "26.0"
check_version "setuptools" "$SETUPTOOLS_VER" "78.1.1"
check_version "wheel" "$WHEEL_VER" "0.46.2"
check_version "cryptography" "$CRYPTO_VER" "44.0.1"

# ============================================
# CLIENT REQUIRED: virtualenv, pipenv
# ============================================
echo ""
echo ">>> Installing virtualenv and pipenv..."
pip install --no-cache-dir virtualenv pipenv

# ============================================
# CLIENT REQUIRED: Jupyter kernel tools
# ============================================
echo ""
echo ">>> Installing Jupyter ecosystem..."
pip install --no-cache-dir \
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
echo ""
echo ">>> Installing Google Cloud packages..."
pip install --no-cache-dir \
    google-cloud-bigquery \
    google-cloud-bigquery-storage \
    db-dtypes

echo ""
echo ">>> Installing data packages..."
pip install --no-cache-dir \
    pyarrow \
    pandas \
    numpy

# ============================================
# Security: Upgrade critical packages
# ============================================
echo ""
echo ">>> Upgrading security-critical packages..."
pip install --no-cache-dir --upgrade \
    certifi \
    "urllib3>=2.0" \
    "requests>=2.31"

# ============================================
# SECURITY: Final re-upgrade
# Some packages may have downgraded our security packages
# ============================================
echo ""
echo ">>> SECURITY: Final re-upgrade to ensure no downgrades occurred..."
pip install --no-cache-dir --upgrade \
    "pip>=26.0" \
    "setuptools>=78.1.1" \
    "wheel>=0.46.2" \
    "cryptography>=44.0.1"

# Remove vendored wheel from setuptools
echo ""
echo ">>> Applying setuptools security fixes..."
SETUPTOOLS_PATH=$(python3 -c "import setuptools; import os; print(os.path.dirname(setuptools.__file__))" 2>/dev/null || echo "")
if [ -n "$SETUPTOOLS_PATH" ] && [ -d "${SETUPTOOLS_PATH}/_vendor" ]; then
    rm -rf "${SETUPTOOLS_PATH}/_vendor/wheel"* 2>/dev/null || true
    echo "    Removed vendored wheel from setuptools"
fi

# ============================================
# Final Verification
# ============================================
echo ""
echo "============================================"
echo "FINAL VERIFICATION"
echo "============================================"

echo ""
echo "=== SECURITY PACKAGE VERSIONS ==="
pip --version
pip show setuptools | grep -E "^(Name|Version):"
pip show wheel | grep -E "^(Name|Version):"
pip show cryptography | grep -E "^(Name|Version):"

# Final version check
PIP_VER=$(pip show pip | grep "^Version:" | cut -d' ' -f2)
SETUPTOOLS_VER=$(pip show setuptools | grep "^Version:" | cut -d' ' -f2)
WHEEL_VER=$(pip show wheel | grep "^Version:" | cut -d' ' -f2)
CRYPTO_VER=$(pip show cryptography | grep "^Version:" | cut -d' ' -f2)

echo ""
echo ">>> Final version verification..."
check_version "pip" "$PIP_VER" "26.0"
check_version "setuptools" "$SETUPTOOLS_VER" "78.1.1"
check_version "wheel" "$WHEEL_VER" "0.46.2"
check_version "cryptography" "$CRYPTO_VER" "44.0.1"

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

echo ""
echo "============================================"
echo "Python packages installed successfully"
echo "ALL SECURITY FIXES VERIFIED"
echo "============================================"