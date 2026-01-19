#!/bin/bash
# GCP Workbench Jupyter Startup Script for Wolfi

set -e

echo "============================================"
echo "  GCP Workbench - Jupyter Server Startup   "
echo "============================================"
echo ""

# Environment info
echo "Environment:"
echo "  User: $(whoami) (UID: $(id -u))"
echo "  Home: ${HOME}"
echo "  Shell: ${SHELL}"
echo "  Python: $(python3 --version 2>&1)"
echo "  R: $(R --version 2>&1 | head -1)"
echo ""

# Ensure directories exist with proper permissions
echo "Setting up directories..."
mkdir -p "${HOME}/.local/share/jupyter/kernels"
mkdir -p "${HOME}/.local/share/jupyter/runtime"
mkdir -p "${HOME}/.jupyter"
mkdir -p "${HOME}/work"

# Verify Jupyter installation
echo ""
echo "Jupyter kernels available:"
jupyter kernelspec list
echo ""

# Check R kernel
if jupyter kernelspec list 2>/dev/null | grep -q "ir"; then
    echo "✓ R kernel is available"
else
    echo "⚠ R kernel not found, attempting to install..."
    R -e "IRkernel::installspec(user = TRUE, name = 'ir', displayname = 'R')" || true
fi

echo ""
echo "Starting JupyterLab on port 8080..."
echo "============================================"

# Start Jupyter Lab with explicit configuration
exec jupyter lab \
    --config="${HOME}/.jupyter/jupyter_server_config.py" \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --notebook-dir="${HOME}" \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True \
    --ServerApp.trust_xheaders=True