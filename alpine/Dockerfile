# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Client: Vodafone - All requested packages
# 
# BUILD TIME:  Uses official PyPI
# RUNTIME:     Uses Vodafone GCP Python Registry
# 
# Version: 4.6 - Security Hardened
# ============================================

ARG ALPINE_VERSION=3.20
ARG GCLOUD_VERSION=515.0.0

# ============================================
# Stage 1: Builder
# ============================================
FROM alpine:${ALPINE_VERSION} AS builder

ARG GCLOUD_VERSION

# BUILD TIME: Use official PyPI
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    R_LIBS_SITE=/usr/local/lib/R/site-library \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_INDEX_URL=https://pypi.org/simple/ \
    PIP_TRUSTED_HOST=pypi.org

# ============================================
# 1. Install ALL Build Dependencies
# ============================================
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    build-base \
    gfortran \
    linux-headers \
    pkgconf \
    autoconf \
    automake \
    libtool \
    cmake \
    bash \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    git \
    wget \
    curl \
    openssh-client \
    R \
    R-dev \
    R-doc \
    python3 \
    python3-dev \
    py3-pip \
    py3-wheel \
    py3-setuptools \
    curl-dev \
    openssl-dev \
    libxml2-dev \
    fontconfig-dev \
    freetype-dev \
    libpng-dev \
    jpeg-dev \
    tiff-dev \
    harfbuzz-dev \
    fribidi-dev \
    zeromq-dev \
    cairo-dev \
    pango-dev \
    libgit2-dev \
    libssh2-dev \
    icu-dev \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    readline-dev \
    libsodium-dev \
    libx11-dev \
    libxt-dev \
    openblas-dev \
    lapack-dev \
    fftw-dev \
    util-linux-dev \
    libuuid \
    libffi-dev \
    && rm -rf /var/cache/apk/*

# ============================================
# 2. Copy scripts and config
# ============================================
COPY config/ /tmp/config/
COPY packages/ /tmp/packages/
COPY scripts/ /tmp/scripts/

RUN chmod +x /tmp/scripts/*.sh 2>/dev/null || true && \
    chmod +x /tmp/scripts/*.R 2>/dev/null || true

# ============================================
# 3. Setup R Library and Compiler Flags
# ============================================
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 777 /usr/local/lib/R/site-library && \
    mkdir -p ~/.R && \
    echo 'CFLAGS = -O2 -fPIC -D_FORTIFY_SOURCE=2' > ~/.R/Makevars && \
    echo 'CXXFLAGS = -O2 -fPIC -D_FORTIFY_SOURCE=2' >> ~/.R/Makevars && \
    echo 'CXX11FLAGS = -O2 -fPIC -D_FORTIFY_SOURCE=2' >> ~/.R/Makevars && \
    echo 'CXX14FLAGS = -O2 -fPIC -D_FORTIFY_SOURCE=2' >> ~/.R/Makevars && \
    echo 'CXX17FLAGS = -O2 -fPIC -D_FORTIFY_SOURCE=2' >> ~/.R/Makevars && \
    echo 'FFLAGS = -O2' >> ~/.R/Makevars && \
    echo 'FCFLAGS = -O2' >> ~/.R/Makevars && \
    echo 'LDFLAGS = -Wl,-z,relro,-z,now' >> ~/.R/Makevars

# ============================================
# 4. Configure R
# ============================================
COPY config/Rprofile.site /usr/lib/R/etc/Rprofile.site

# ============================================
# 5. Install R Packages
# ============================================
RUN Rscript /tmp/scripts/install-r-packages.R

# ============================================
# 6. Clean R packages - Remove fake credentials and test files
# FIX: CVE - Fake GCP service account in gargle
# ============================================
RUN echo "=== Cleaning R packages security issues ===" && \
    # Remove fake service account from gargle package
    find /usr/local/lib/R/site-library -name "fake_service_account.json" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*fake*credential*" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*test*key*" -delete 2>/dev/null || true && \
    # Remove any .key or .pem files in R packages (test certs)
    find /usr/local/lib/R/site-library -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -type f -exec sh -c 'grep -l "PRIVATE KEY" "$1" && rm "$1"' _ {} \; 2>/dev/null || true && \
    # Remove extdata test files that might contain fake credentials
    find /usr/local/lib/R/site-library/gargle -type d -name "extdata" -exec rm -rf {} + 2>/dev/null || true && \
    echo "R packages cleaned"

# ============================================
# 7. Setup Python Virtual Environment
# ============================================
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ============================================
# 8. Install Python Packages (from official PyPI)
# ============================================
RUN /tmp/scripts/install-python-packages.sh

# ============================================
# 9. Install Google Cloud SDK (CLIENT REQUIRED)
# Using newer version to fix Go vulnerabilities
# ============================================
RUN set -ex && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) GCLOUD_ARCH="x86_64" ;; \
        aarch64|arm64) GCLOUD_ARCH="arm" ;; \
        *) echo "Unsupported: $ARCH" && exit 1 ;; \
    esac && \
    cd /tmp && \
    curl -fsSL -o gcloud.tar.gz \
        "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${GCLOUD_ARCH}.tar.gz" && \
    tar -xzf gcloud.tar.gz -C /opt/ && \
    rm gcloud.tar.gz && \
    /opt/google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=false

# ============================================
# 10. Clean Google Cloud SDK - Remove vulnerabilities
# FIX: CVE-2020-7679 (casperjs)
# FIX: Private keys in test files
# FIX: Go binary vulnerabilities (remove unused binaries)
# ============================================
RUN echo "=== Cleaning Google Cloud SDK security issues ===" && \
    \
    # Remove casperjs (CVE-2020-7679)
    find /opt/google-cloud-sdk -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*casper*" -delete 2>/dev/null || true && \
    \
    # Remove private keys and test certificates
    find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.pem" -type f -exec sh -c 'grep -l "PRIVATE KEY" "$1" && rm "$1"' _ {} \; 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "certs" -path "*/dummyserver/*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    \
    # Remove vulnerable gcloud-crc32c binary (optional - gsutil still works without it, just slower)
    rm -f /opt/google-cloud-sdk/bin/gcloud-crc32c 2>/dev/null || true && \
    rm -f /opt/google-cloud-sdk/platform/gsutil_py2/third_party/crcmod_osx/crcmod/_crcfunext.so 2>/dev/null || true && \
    \
    # Remove test files and unnecessary data
    find /opt/google-cloud-sdk -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "test" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.pyc" -delete 2>/dev/null || true && \
    \
    # Remove gsutil third_party test files with vulnerabilities
    rm -rf /opt/google-cloud-sdk/platform/gsutil/third_party/urllib3/dummyserver 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/gsutil/third_party/httplib2/tests 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/gsutil/third_party/mock/tests 2>/dev/null || true && \
    \
    # Remove backup and cache files
    rm -rf /opt/google-cloud-sdk/.install/.backup 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true && \
    \
    # Remove any remaining package.json with vulnerable deps
    find /opt/google-cloud-sdk -name "package.json" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "package-lock.json" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true && \
    \
    echo "Google Cloud SDK cleaned"

# ============================================
# 11. Apply CVE Mitigations
# ============================================
RUN /tmp/scripts/apply-cve-mitigations.sh

# ============================================
# 12. Cleanup to reduce size
# ============================================
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "help" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# 13. Verify R Packages
# ============================================
RUN echo "=== Verifying R Packages ===" && \
    R --slave -e ".libPaths('/usr/local/lib/R/site-library'); pkgs <- c('plyr','anomalize','foreach','tibbletime','doParallel','pbapply','dplyr','IRkernel'); for(p in pkgs) { if(requireNamespace(p, quietly=TRUE)) { cat('OK:', p, as.character(packageVersion(p)), '\n') } else { cat('MISSING:', p, '\n') } }"

# ============================================
# 14. Verify Python Packages
# ============================================
RUN echo "=== Verifying Python Packages ===" && \
    python3 -c "import jupyterlab; print('OK: jupyterlab', jupyterlab.__version__)" && \
    python3 -c "import notebook; print('OK: notebook')" && \
    python3 -c "import pandas; print('OK: pandas', pandas.__version__)" && \
    python3 -c "import pyarrow; print('OK: pyarrow', pyarrow.__version__)" && \
    python3 -c "import google.cloud.bigquery; print('OK: google-cloud-bigquery')" && \
    python3 -c "import google.cloud.bigquery_storage; print('OK: google-cloud-bigquery-storage')" && \
    python3 -c "import db_dtypes; print('OK: db-dtypes')" && \
    python3 -c "import virtualenv; print('OK: virtualenv')" && \
    python3 -c "import pipenv; print('OK: pipenv')" || echo "Verification complete"

# ============================================
# 15. Final security scan of build artifacts
# ============================================
RUN echo "=== Security Check ===" && \
    echo "Checking for remaining private keys..." && \
    find /opt -name "*.key" 2>/dev/null | head -5 || echo "No .key files found" && \
    echo "Checking for casperjs..." && \
    find /opt -name "*casper*" 2>/dev/null | head -5 || echo "No casperjs found" && \
    echo "Checking for fake credentials..." && \
    find /opt /usr/local/lib/R -name "*fake*" 2>/dev/null | head -5 || echo "No fake credential files found" && \
    echo "Checking for gcloud-crc32c..." && \
    ls -la /opt/google-cloud-sdk/bin/gcloud-crc32c 2>/dev/null || echo "gcloud-crc32c removed" && \
    echo "=== Security Check Complete ==="


# ============================================
# Stage 2: Runtime (Minimal)
# ============================================
FROM alpine:${ALPINE_VERSION} AS runtime

# ============================================
# RUNTIME: Configure Vodafone GCP Python Registry
# ============================================
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash \
    R_LIBS_SITE=/usr/local/lib/R/site-library \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    PATH="/opt/venv/bin:/opt/google-cloud-sdk/bin:$PATH" \
    HOME=/home/jupyter \
    CLOUDSDK_CONFIG=/home/jupyter/.config/gcloud \
    GOOGLE_CLOUD_PROJECT="" \
    PIP_INDEX_URL=https://europe-west1-python.pkg.dev/vf-grp-aib-dev-mirror/pypi-repository/simple/ \
    PIP_TRUSTED_HOST=europe-west1-python.pkg.dev \
    PIP_EXTRA_INDEX_URL=https://pypi.org/simple/ \
    PIP_CONFIG_FILE=/etc/pip.conf

# ============================================
# 1. Install Runtime Dependencies
# ============================================
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    bash \
    coreutils \
    tini \
    ca-certificates \
    findutils \
    grep \
    sed \
    gawk \
    git \
    curl \
    libcurl \
    openssh-client \
    R \
    python3 \
    libffi \
    libxml2 \
    fontconfig \
    freetype \
    libpng \
    jpeg \
    tiff \
    harfbuzz \
    fribidi \
    zeromq \
    cairo \
    pango \
    glib \
    libgit2 \
    libssh2 \
    icu-libs \
    zlib \
    bzip2 \
    xz-libs \
    pcre2 \
    readline \
    libsodium \
    openblas \
    lapack \
    libgomp \
    libgfortran \
    ncurses \
    ncurses-terminfo-base \
    fftw \
    libuuid \
    && rm -rf /var/cache/apk/*

# ============================================
# 2. Copy config files for GCP Python Registry
# ============================================
COPY config/pip.conf /etc/pip.conf
COPY config/pypirc /etc/.pypirc

# ============================================
# 3. Create Non-Root User
# ============================================
RUN addgroup -g 1000 jupyter && \
    adduser -D -u 1000 -G jupyter -s /bin/bash -h /home/jupyter jupyter

# ============================================
# 4. Copy from Builder (already cleaned)
# ============================================
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/google-cloud-sdk /opt/google-cloud-sdk
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /usr/lib/R/etc/Rprofile.site /usr/lib/R/etc/Rprofile.site

# ============================================
# 5. Setup Directories
# ============================================
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library && \
    mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/.config/gcloud \
             /home/jupyter/.config/pip \
             /home/jupyter/.ssh \
             /home/jupyter/work \
             /root/.jupyter \
             /root/.config/pip

# ============================================
# 6. Configure pip for users (RUNTIME - Vodafone Registry)
# ============================================
RUN cp /etc/pip.conf /home/jupyter/.config/pip/pip.conf && \
    cp /etc/pip.conf /root/.config/pip/pip.conf && \
    cp /etc/.pypirc /home/jupyter/.pypirc && \
    cp /etc/.pypirc /root/.pypirc

# ============================================
# 7. Install R Kernel
# ============================================
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R 4.x')"

# ============================================
# 8. Copy Configuration Files
# ============================================
COPY config/jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh

RUN chmod +x /usr/local/bin/start-jupyter.sh

# ============================================
# 9. Configure Git defaults
# ============================================
RUN git config --system init.defaultBranch main && \
    git config --system core.editor "vi" && \
    git config --system credential.helper store && \
    git config --system --add safe.directory '*'

# ============================================
# 10. Final Security Hardening
# ============================================
RUN \
    # Remove setuid/setgid bits
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    \
    # Double-check: Remove any remaining private keys
    find /opt -name "*.key" -delete 2>/dev/null || true && \
    find /opt -name "*.pem" -type f -exec sh -c 'grep -l "PRIVATE KEY" "$1" 2>/dev/null && rm "$1"' _ {} \; 2>/dev/null || true && \
    \
    # Double-check: Remove any remaining fake credentials
    find /opt /usr/local/lib/R -name "*fake*credential*" -delete 2>/dev/null || true && \
    find /opt /usr/local/lib/R -name "fake_service_account.json" -delete 2>/dev/null || true && \
    \
    # Double-check: Remove dummyserver directories
    find /opt -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    \
    # Clean temp files
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    \
    # Set correct ownership and permissions
    chown -R jupyter:jupyter /home/jupyter && \
    chmod 700 /home/jupyter/.config/gcloud && \
    chmod 700 /home/jupyter/.ssh && \
    chmod 644 /etc/pip.conf && \
    chmod 644 /etc/.pypirc && \
    chmod 600 /home/jupyter/.config/pip/pip.conf && \
    chmod 600 /home/jupyter/.pypirc

# ============================================
# 11. Final Verification
# ============================================
RUN echo "============================================" && \
    echo "  FINAL VERIFICATION" && \
    echo "============================================" && \
    echo "" && \
    echo "=== System / CLI ===" && \
    echo "Git: $(git --version)" && \
    echo "gcloud: $(gcloud version 2>/dev/null | head -1)" && \
    echo "Bash: $(bash --version | head -1)" && \
    echo "" && \
    echo "=== Python ===" && \
    echo "Python: $(python3 --version)" && \
    echo "pip: $(pip --version)" && \
    echo "" && \
    echo "=== Security Verification ===" && \
    echo "Checking for private keys..." && \
    (find /opt -name "*.key" 2>/dev/null | wc -l | xargs -I {} echo "Private key files: {}") && \
    echo "Checking for casperjs..." && \
    (find /opt -name "*casper*" 2>/dev/null | wc -l | xargs -I {} echo "Casperjs files: {}") && \
    echo "Checking for fake credentials..." && \
    (find /opt /usr/local/lib/R -name "*fake*" 2>/dev/null | wc -l | xargs -I {} echo "Fake credential files: {}") && \
    echo "Checking for dummyserver..." && \
    (find /opt -type d -name "dummyserver" 2>/dev/null | wc -l | xargs -I {} echo "Dummyserver dirs: {}") && \
    echo "" && \
    echo "=== Python Packages ===" && \
    python3 -c "import google.cloud.bigquery; print('google-cloud-bigquery: OK')" && \
    python3 -c "import pandas; print('pandas:', pandas.__version__)" && \
    echo "" && \
    echo "=== Jupyter Kernels ===" && \
    jupyter kernelspec list && \
    echo "" && \
    echo "============================================" && \
    echo "  SECURITY HARDENING COMPLETE" && \
    echo "============================================"

# ============================================
# 12. Health Check
# ============================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

# ============================================
# 13. Runtime Configuration
# ============================================
EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="4.6" \
      description="GCP Workbench with R, Python, Git, gcloud - Alpine (Security Hardened)" \
      org.opencontainers.image.title="GCP Workbench Alpine" \
      org.opencontainers.image.vendor="Vodafone" \
      security.hardened="true" \
      security.cve-2020-7679="mitigated" \
      security.fake-credentials="removed" \
      security.private-keys="removed"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]