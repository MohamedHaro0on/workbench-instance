#!/bin/bash
# ============================================
# Google Cloud SDK Installation Script
# Minimal secure installation
# ============================================

set -e

echo "============================================"
echo "Installing Google Cloud SDK"
echo "============================================"

GCLOUD_VERSION="${GCLOUD_VERSION:-485.0.0}"
ARCH=$(uname -m)

# Determine architecture
case "$ARCH" in
    x86_64)
        GCLOUD_ARCH="x86_64"
        ;;
    aarch64|arm64)
        GCLOUD_ARCH="arm"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download
cd /tmp
GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${GCLOUD_ARCH}.tar.gz"

echo "Downloading Google Cloud SDK v${GCLOUD_VERSION}..."
curl -fsSL -o google-cloud-sdk.tar.gz "$GCLOUD_URL"

# Extract to /opt
tar -xzf google-cloud-sdk.tar.gz -C /opt/
rm google-cloud-sdk.tar.gz

# Install without prompts
/opt/google-cloud-sdk/install.sh \
    --quiet \
    --usage-reporting=false \
    --path-update=false \
    --command-completion=false

# Create symlinks
ln -sf /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud
ln -sf /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil
ln -sf /opt/google-cloud-sdk/bin/bq /usr/local/bin/bq

# Security cleanup
echo "Cleaning up Google Cloud SDK..."
rm -rf /opt/google-cloud-sdk/.install/.backup 2>/dev/null || true
rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true
find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true
find /opt/google-cloud-sdk -name "*.pem" -delete 2>/dev/null || true
find /opt/google-cloud-sdk -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
find /opt/google-cloud-sdk -type d -name "test" -exec rm -rf {} + 2>/dev/null || true

# Verify installation
echo "Verifying installation..."
gcloud --version

echo "============================================"
echo "Google Cloud SDK installed successfully"
echo "============================================"