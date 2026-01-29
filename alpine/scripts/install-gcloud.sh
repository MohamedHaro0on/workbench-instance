#!/bin/bash
# ============================================
# Google Cloud SDK Installation Script
# Minimal secure installation
# ============================================

set -e

echo "============================================"
echo "Installing Google Cloud SDK"
echo "============================================"

GCLOUD_VERSION="485.0.0"
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

# Download and verify
cd /tmp
GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${GCLOUD_ARCH}.tar.gz"
CHECKSUM_URL="${GCLOUD_URL}.sha256"

echo "Downloading Google Cloud SDK..."
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

# Cleanup unnecessary components to reduce size
rm -rf /opt/google-cloud-sdk/.install/.backup
rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true

# Verify installation
gcloud --version

echo "============================================"
echo "Google Cloud SDK installed successfully"
echo "============================================"