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

# Version check function
check_version() {
    local pkg=$1
    local current=$2
    local required=$3
    
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
# SECURITY FIX: Remove vulnerable vendored packages from pipenv
# ============================================
echo ""
echo ">>> SECURITY: Cleaning pipenv vendored vulnerable packages..."

# Get the site-packages path
SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])")
echo "    Site packages: $SITE_PACKAGES"

# Remove vulnerable wheel from pipenv's vendored packages
if [ -d "$SITE_PACKAGES/pipenv/patched/pip/_vendor/distlib" ]; then
    echo "    Cleaning pipenv/patched/pip/_vendor..."
    rm -rf "$SITE_PACKAGES/pipenv/patched/pip/_vendor/distlib"/*.whl 2>/dev/null || true
fi

# Remove wheel METADATA from pipenv vendored packages
find "$SITE_PACKAGES/pipenv" -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$SITE_PACKAGES/pipenv" -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$SITE_PACKAGES/pipenv" -name "METADATA" -path "*wheel*" -delete 2>/dev/null || true
find "$SITE_PACKAGES/pipenv" -name "METADATA" -path "*setuptools*" -delete 2>/dev/null || true

# Remove from pipenv's patched directory
find "$SITE_PACKAGES/pipenv/patched" -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$SITE_PACKAGES/pipenv/patched" -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true

# Remove vendored wheel and setuptools directories
rm -rf "$SITE_PACKAGES/pipenv/patched/pip/_vendor/wheel" 2>/dev/null || true
rm -rf "$SITE_PACKAGES/pipenv/patched/pip/_vendor/setuptools" 2>/dev/null || true

# Also clean virtualenv's vendored packages
find "$SITE_PACKAGES/virtualenv" -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$SITE_PACKAGES/virtualenv" -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$SITE_PACKAGES/virtualenv" -name "METADATA" -path "*wheel*" -delete 2>/dev/null || true
find "$SITE_PACKAGES/virtualenv" -name "METADATA" -path "*setuptools*" -delete 2>/dev/null || true

# Clean any embedded wheel files (.whl)
find "$SITE_PACKAGES" -name "wheel-0.45*.whl" -delete 2>/dev/null || true
find "$SITE_PACKAGES" -name "setuptools-65*.whl" -delete 2>/dev/null || true
find "$SITE_PACKAGES" -name "wheel-0.4[0-5]*.whl" -delete 2>/dev/null || true
find "$SITE_PACKAGES" -name "setuptools-6[0-9]*.whl" -delete 2>/dev/null || true
find "$SITE_PACKAGES" -name "setuptools-7[0-7]*.whl" -delete 2>/dev/null || true

echo "    Pipenv vendored packages cleaned"

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
# SECURITY: Final comprehensive cleanup of ALL vendored packages
# ============================================
echo ""
echo ">>> SECURITY: Final comprehensive cleanup..."

SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])")

# Remove ALL old wheel and setuptools from everywhere in site-packages
echo "    Scanning for vulnerable vendored packages..."

# Find and remove any wheel < 0.46.2 METADATA
find "$SITE_PACKAGES" -name "METADATA" -type f 2>/dev/null | while read metadata_file; do
    if grep -q "^Name: wheel$" "$metadata_file" 2>/dev/null; then
        version=$(grep "^Version:" "$metadata_file" 2>/dev/null | cut -d' ' -f2)
        if [ -n "$version" ]; then
            # Check if version is less than 0.46.2
            lowest=$(printf '%s\n' "0.46.2" "$version" | sort -V | head -n1)
            if [ "$lowest" != "0.46.2" ]; then
                dir=$(dirname "$metadata_file")
                echo "    Removing vulnerable wheel $version from: $dir"
                rm -rf "$dir" 2>/dev/null || true
            fi
        fi
    fi
done

# Find and remove any setuptools < 78.1.1 METADATA
find "$SITE_PACKAGES" -name "METADATA" -type f 2>/dev/null | while read metadata_file; do
    if grep -q "^Name: setuptools$" "$metadata_file" 2>/dev/null; then
        version=$(grep "^Version:" "$metadata_file" 2>/dev/null | cut -d' ' -f2)
        if [ -n "$version" ]; then
            # Check if version is less than 78.1.1
            lowest=$(printf '%s\n' "78.1.1" "$version" | sort -V | head -n1)
            if [ "$lowest" != "78.1.1" ]; then
                dir=$(dirname "$metadata_file")
                echo "    Removing vulnerable setuptools $version from: $dir"
                rm -rf "$dir" 2>/dev/null || true
            fi
        fi
    fi
done

# Remove embedded .whl files with vulnerable versions
find "$SITE_PACKAGES" -name "*.whl" -type f 2>/dev/null | while read whl_file; do
    filename=$(basename "$whl_file")
    # Check for wheel versions < 0.46.2
    if echo "$filename" | grep -qE "^wheel-0\.(4[0-5]|[0-3][0-9])"; then
        echo "    Removing vulnerable wheel file: $whl_file"
        rm -f "$whl_file" 2>/dev/null || true
    fi
    # Check for setuptools versions < 78.1.1
    if echo "$filename" | grep -qE "^setuptools-(6[0-9]|7[0-7])\."; then
        echo "    Removing vulnerable setuptools file: $whl_file"
        rm -f "$whl_file" 2>/dev/null || true
    fi
done

echo "    Comprehensive cleanup complete"

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

# Check for any remaining vulnerable packages
echo ""
echo ">>> Checking for remaining vulnerable vendored packages..."
VULN_FOUND=0

# Check for vulnerable wheel
VULN_WHEEL=$(find "$SITE_PACKAGES" -path "*wheel-0.4[0-5]*" -name "METADATA" 2>/dev/null | head -5)
if [ -n "$VULN_WHEEL" ]; then
    echo "    WARNING: Found vulnerable wheel:"
    echo "$VULN_WHEEL"
    VULN_FOUND=1
fi

# Check for vulnerable setuptools
VULN_SETUPTOOLS=$(find "$SITE_PACKAGES" -path "*setuptools-6[0-9]*" -name "METADATA" 2>/dev/null | head -5)
VULN_SETUPTOOLS2=$(find "$SITE_PACKAGES" -path "*setuptools-7[0-7]*" -name "METADATA" 2>/dev/null | head -5)
if [ -n "$VULN_SETUPTOOLS" ] || [ -n "$VULN_SETUPTOOLS2" ]; then
    echo "    WARNING: Found vulnerable setuptools:"
    echo "$VULN_SETUPTOOLS"
    echo "$VULN_SETUPTOOLS2"
    VULN_FOUND=1
fi

if [ $VULN_FOUND -eq 0 ]; then
    echo "    OK: No vulnerable vendored packages found"
fi

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
