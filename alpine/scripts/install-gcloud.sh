#!/bin/bash
# ============================================
# Google Cloud SDK Installation Script
# Minimal secure installation
# ============================================

set -e

echo "============================================"
echo "Installing Google Cloud SDK"
echo "============================================"

GCLOUD_VERSION="${GCLOUD_VERSION:-513.0.0}"
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)  GCLOUD_ARCH="x86_64" ;;
    aarch64|arm64) GCLOUD_ARCH="arm" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

cd /tmp
GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${GCLOUD_ARCH}.tar.gz"

echo "Downloading Google Cloud SDK v${GCLOUD_VERSION}..."
curl -fsSL -o google-cloud-sdk.tar.gz "$GCLOUD_URL"

tar -xzf google-cloud-sdk.tar.gz -C /opt/
rm google-cloud-sdk.tar.gz

/opt/google-cloud-sdk/install.sh \
    --quiet \
    --usage-reporting=false \
    --path-update=false \
    --command-completion=false

# Create symlinks
ln -sf /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud
ln -sf /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil
ln -sf /opt/google-cloud-sdk/bin/bq /usr/local/bin/bq

echo "Cleaning up Google Cloud SDK..."
rm -rf /opt/google-cloud-sdk/.install/.backup 2>/dev/null || true
rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true
find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true

# ============================================
# SURGICAL test directory removal:
# PRESERVE: gslib/tests (gsutil requires it at runtime!)
# REMOVE:   all other test dirs that are not functional dependencies
# ============================================
echo "Removing non-essential test directories (preserving gslib/tests)..."

find /opt/google-cloud-sdk -type d -name "tests" \
    ! -path "*/gslib/tests*" \
    ! -path "*/gslib/*" \
    -exec rm -rf {} + 2>/dev/null || true

find /opt/google-cloud-sdk -type d -name "test" \
    ! -path "*/gslib/*" \
    -exec rm -rf {} + 2>/dev/null || true

find /opt/google-cloud-sdk -type d -name "dummyserver" \
    ! -path "*/gslib/*" \
    -exec rm -rf {} + 2>/dev/null || true

# Verify gsutil still works after cleanup
echo "Verifying gsutil..."
python3 /opt/google-cloud-sdk/platform/gsutil/gsutil version || {
    echo "ERROR: gsutil broken after cleanup!"
    exit 1
}

echo "Verifying gcloud..."
gcloud --version

echo "============================================"
echo "Google Cloud SDK installed successfully"
echo "============================================"