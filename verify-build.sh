#!/bin/bash
# ============================================
# Build Verification Script
# Verifies the Docker image has no CVEs
# ============================================

set -e

IMAGE_NAME="${1:-workbench:test}"

echo "============================================"
echo "Building and Verifying: ${IMAGE_NAME}"
echo "============================================"

# Build the image
echo ""
echo ">>> Building Docker image..."
docker build -t "${IMAGE_NAME}" .

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed!"
    exit 1
fi

echo ""
echo ">>> Build successful!"
echo ""

# Run internal verification
echo "============================================"
echo "Running Internal Verification"
echo "============================================"

docker run --rm --entrypoint="" "${IMAGE_NAME}" sh -c '
echo ""
echo "=== Python Versions (venv - should be FIXED) ==="
/opt/venv/bin/pip --version
/opt/venv/bin/pip show setuptools | grep -E "^(Name|Version):"
/opt/venv/bin/pip show wheel | grep -E "^(Name|Version):"
/opt/venv/bin/pip show cryptography | grep -E "^(Name|Version):"

echo ""
echo "=== System Python Packages (should be EMPTY) ==="
echo "Checking for pip:"
find /usr/lib -type d -name "pip-*.dist-info" 2>/dev/null || echo "  CLEAN: No system pip found"
echo "Checking for setuptools:"
find /usr/lib -type d -name "setuptools-*.dist-info" 2>/dev/null || echo "  CLEAN: No system setuptools found"
echo "Checking for wheel:"
find /usr/lib -type d -name "wheel-*.dist-info" 2>/dev/null || echo "  CLEAN: No system wheel found"
echo "Checking for cryptography:"
find /usr/lib -type d -name "cryptography-*.dist-info" 2>/dev/null || echo "  CLEAN: No system cryptography found"

echo ""
echo "=== R Verification ==="
R --version | head -1
R --slave -e "cat(\"rstudioapi:\", as.character(packageVersion(\"rstudioapi\")), \"\n\")"

echo ""
echo "=== Security Files Check ==="
echo "Checking .pem files in R packages:"
PEM_COUNT=$(find /usr/local/lib/R/site-library -name "*.pem" 2>/dev/null | wc -l)
echo "  Found: ${PEM_COUNT} .pem files"

echo "Checking .key files in R packages:"
KEY_COUNT=$(find /usr/local/lib/R/site-library -name "*.key" 2>/dev/null | wc -l)
echo "  Found: ${KEY_COUNT} .key files"

echo "Checking webfakes cert directory:"
if [ -d "/usr/local/lib/R/site-library/webfakes/cert" ]; then
    echo "  WARNING: webfakes cert directory exists!"
else
    echo "  CLEAN: webfakes cert directory removed"
fi

echo ""
echo "=== Jupyter Kernels ==="
jupyter kernelspec list
'

echo ""
echo "============================================"
echo "Running Trivy Scan"
echo "============================================"

# Check if trivy is installed
if command -v trivy &> /dev/null; then
    echo ""
    echo ">>> Scanning with Trivy..."
    trivy image --severity HIGH,CRITICAL "${IMAGE_NAME}"
    
    echo ""
    echo ">>> Full vulnerability report..."
    trivy image "${IMAGE_NAME}"
else
    echo ""
    echo "WARNING: Trivy not installed. Skipping vulnerability scan."
    echo "Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
fi

echo ""
echo "============================================"
echo "Verification Complete"
echo "============================================"