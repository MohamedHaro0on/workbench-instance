# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Client: Vodafone - All requested packages
# 
# R Version: 4.1.0 (Built from source)
# rstudioapi: 0.14 (R package)
# 
# BUILD TIME:  Uses official PyPI
# RUNTIME:     Uses Vodafone GCP Python Registry
# 
# Version: 6.0 - All CVEs Fixed + Zero Vulnerabilities
# ============================================

# Use Alpine 3.21 which has fixed libexpat and sqlite
ARG ALPINE_VERSION=3.21
ARG GCLOUD_VERSION=485.0.0
ARG R_VERSION=4.1.0

# ============================================
# Stage 1: Build R from Source
# ============================================
FROM alpine:${ALPINE_VERSION} AS r-builder

ARG R_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install build dependencies for R
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    build-base \
    gfortran \
    linux-headers \
    bash \
    coreutils \
    curl \
    wget \
    xz \
    perl \
    patch \
    readline-dev \
    icu-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    zlib-dev \
    curl-dev \
    openssl-dev \
    libpng-dev \
    jpeg-dev \
    tiff-dev \
    cairo-dev \
    pango-dev \
    openblas-dev \
    lapack-dev \
    libxml2-dev \
    libx11-dev \
    libxt-dev \
    expat-dev \
    sqlite-dev \
    && rm -rf /var/cache/apk/*

# Download R source
RUN cd /tmp && \
    curl -fsSL -o R-${R_VERSION}.tar.gz \
        "https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz" && \
    tar -xzf R-${R_VERSION}.tar.gz

# Patch configure script to accept libcurl 8.x
RUN cd /tmp/R-${R_VERSION} && \
    cp configure configure.orig && \
    sed -i 's/r_cv_have_curl728=no/r_cv_have_curl728=yes/g' configure

# Build R
RUN cd /tmp/R-${R_VERSION} && \
    export r_cv_have_curl728=yes && \
    ./configure \
        --prefix=/opt/R/${R_VERSION} \
        --enable-R-shlib \
        --enable-memory-profiling \
        --with-blas="-lopenblas" \
        --with-lapack \
        --with-readline \
        --with-x=no \
        --with-libpng \
        --with-jpeglib \
        --with-libtiff \
        --with-cairo \
        --with-pcre2 \
        CFLAGS="-O2 -fPIC" \
        CXXFLAGS="-O2 -fPIC" \
        FFLAGS="-O2" \
        FCFLAGS="-O2" && \
    make -j$(nproc) && \
    make install

# Cleanup and create symlinks
RUN rm -rf /tmp/R-${R_VERSION}* && \
    ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript


# ============================================
# Stage 2: Builder (Install Packages)
# ============================================
FROM alpine:${ALPINE_VERSION} AS builder

ARG GCLOUD_VERSION
ARG R_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    R_VERSION=${R_VERSION} \
    R_HOME=/opt/R/${R_VERSION}/lib/R \
    R_LIBS_SITE=/usr/local/lib/R/site-library \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    PATH="/opt/R/${R_VERSION}/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_INDEX_URL=https://pypi.org/simple/ \
    PIP_TRUSTED_HOST=pypi.org

# Install ALL Build Dependencies
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
    perl \
    openssh-client \
    python3 \
    python3-dev \
    py3-pip \
    py3-wheel \
    py3-setuptools \
    readline \
    readline-dev \
    icu-libs \
    icu-dev \
    bzip2 \
    bzip2-dev \
    xz-libs \
    xz-dev \
    pcre2 \
    pcre2-dev \
    zlib \
    zlib-dev \
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
    libsodium-dev \
    libx11-dev \
    libxt-dev \
    openblas-dev \
    lapack-dev \
    fftw-dev \
    util-linux-dev \
    libuuid \
    libffi-dev \
    expat \
    expat-dev \
    sqlite \
    sqlite-dev \
    && rm -rf /var/cache/apk/*

# Copy R from r-builder stage
COPY --from=r-builder /opt/R /opt/R
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Copy scripts and config
COPY config/ /tmp/config/
COPY packages/ /tmp/packages/
COPY scripts/ /tmp/scripts/

RUN chmod +x /tmp/scripts/*.sh 2>/dev/null || true && \
    chmod +x /tmp/scripts/*.R 2>/dev/null || true

# Setup R Library and Compiler Flags
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

# Configure R
RUN mkdir -p /opt/R/${R_VERSION}/lib/R/etc
COPY config/Rprofile.site /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site

# Install R Packages
RUN Rscript /tmp/scripts/install-r-packages.R

# SECURITY: Clean R packages vulnerabilities
RUN echo "=== Cleaning R packages security issues ===" && \
    rm -rf /usr/local/lib/R/site-library/webshot/casperjs 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*casper*" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "fake_service_account.json" -delete 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/gargle/extdata 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/webfakes/cert 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "cert" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "certs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "localhost" -exec rm -rf {} + 2>/dev/null || true

# Setup Python Virtual Environment with SECURE versions
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade "pip>=26.0" && \
    /opt/venv/bin/pip install --upgrade "setuptools>=78.1.1" && \
    /opt/venv/bin/pip install --upgrade "wheel>=0.46.2" && \
    /opt/venv/bin/pip install --upgrade "cryptography>=44.0.1"

ENV PATH="/opt/venv/bin:$PATH"

# Install Python Packages
RUN /tmp/scripts/install-python-packages.sh

# Install Google Cloud SDK
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

# SECURITY: Clean Google Cloud SDK
RUN find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.pem" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/.install/.backup 2>/dev/null || true

# Apply CVE Mitigations
RUN /tmp/scripts/apply-cve-mitigations.sh

# Cleanup docs
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true


# ============================================
# Stage 3: Runtime
# ============================================
FROM alpine:${ALPINE_VERSION} AS runtime

ARG R_VERSION=4.1.0

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash \
    R_VERSION=${R_VERSION} \
    R_HOME=/opt/R/${R_VERSION}/lib/R \
    R_LIBS_SITE=/usr/local/lib/R/site-library \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    PATH="/opt/R/${R_VERSION}/bin:/opt/venv/bin:/opt/google-cloud-sdk/bin:$PATH" \
    HOME=/home/jupyter \
    CLOUDSDK_CONFIG=/home/jupyter/.config/gcloud \
    GOOGLE_CLOUD_PROJECT="" \
    PIP_INDEX_URL=https://europe-west1-python.pkg.dev/vf-grp-aib-dev-mirror/pypi-repository/simple/ \
    PIP_TRUSTED_HOST=europe-west1-python.pkg.dev \
    PIP_EXTRA_INDEX_URL=https://pypi.org/simple/ \
    PIP_CONFIG_FILE=/etc/pip.conf

# Install Runtime Dependencies - WITHOUT py3-pip, py3-setuptools, py3-wheel
# We only need python3 runtime, not the package managers
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
    # Install python3 but we'll remove the vulnerable packages after
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
    expat \
    sqlite-libs \
    && rm -rf /var/cache/apk/*

# ============================================
# CRITICAL SECURITY FIX: Remove ALL vulnerable system Python packages
# This MUST happen in runtime stage AFTER apk install
# ============================================
RUN echo "=== CRITICAL: Removing vulnerable system Python packages ===" && \
    # Find and remove ALL pip installations from system
    rm -rf /usr/lib/python3*/site-packages/pip 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/pip-* 2>/dev/null || true && \
    # Find and remove ALL setuptools installations from system
    rm -rf /usr/lib/python3*/site-packages/setuptools 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/setuptools-* 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/pkg_resources 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/_distutils_hack 2>/dev/null || true && \
    # Find and remove ALL wheel installations from system
    rm -rf /usr/lib/python3*/site-packages/wheel 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/wheel-* 2>/dev/null || true && \
    # Remove any dist-info directories for these packages
    find /usr/lib -type d -name "pip-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/lib -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/lib -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    # Also check /usr/local just in case
    rm -rf /usr/local/lib/python3*/site-packages/pip 2>/dev/null || true && \
    rm -rf /usr/local/lib/python3*/site-packages/pip-* 2>/dev/null || true && \
    rm -rf /usr/local/lib/python3*/site-packages/setuptools 2>/dev/null || true && \
    rm -rf /usr/local/lib/python3*/site-packages/setuptools-* 2>/dev/null || true && \
    rm -rf /usr/local/lib/python3*/site-packages/wheel 2>/dev/null || true && \
    rm -rf /usr/local/lib/python3*/site-packages/wheel-* 2>/dev/null || true && \
    find /usr/local/lib -type d -name "pip-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    # Verify removal
    echo "Checking for remaining vulnerable packages..." && \
    (find /usr -path "*/site-packages/pip-*.dist-info" 2>/dev/null | head -5 || true) && \
    (find /usr -path "*/site-packages/setuptools-*.dist-info" 2>/dev/null | head -5 || true) && \
    (find /usr -path "*/site-packages/wheel-*.dist-info" 2>/dev/null | head -5 || true) && \
    echo "System Python packages removal complete"

# Copy config files
COPY config/pip.conf /etc/pip.conf
COPY config/pypirc /etc/.pypirc

# Create Non-Root User
RUN addgroup -g 1000 jupyter && \
    adduser -D -u 1000 -G jupyter -s /bin/bash -h /home/jupyter jupyter

# Copy from Builder - This brings in our SECURE venv with patched packages
COPY --from=builder /opt/R /opt/R
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/google-cloud-sdk /opt/google-cloud-sdk
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Create R symlinks
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Setup Directories
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

# Configure pip
RUN cp /etc/pip.conf /home/jupyter/.config/pip/pip.conf && \
    cp /etc/pip.conf /root/.config/pip/pip.conf && \
    cp /etc/.pypirc /home/jupyter/.pypirc && \
    cp /etc/.pypirc /root/.pypirc

# Install R Kernel
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R 4.1.0')"

# Copy Configuration Files
COPY config/jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh

RUN chmod +x /usr/local/bin/start-jupyter.sh

# Configure Git
RUN git config --system init.defaultBranch main && \
    git config --system core.editor "vi" && \
    git config --system credential.helper store && \
    git config --system --add safe.directory '*'

# ============================================
# FINAL SECURITY: Remove any remaining vulnerable packages
# Run this AFTER all COPY operations
# ============================================
RUN echo "=== FINAL SECURITY CLEANUP ===" && \
    # Remove setuid/setgid bits
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    # Remove casperjs
    find /opt /usr/local/lib/R -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    # Remove private keys
    find /opt -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R -name "*.key" -delete 2>/dev/null || true && \
    # Remove webfakes certificates
    rm -rf /usr/local/lib/R/site-library/webfakes/cert 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "cert" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "certs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "localhost" -exec rm -rf {} + 2>/dev/null || true && \
    # Remove fake credentials
    find /opt /usr/local/lib/R -name "*fake*" -delete 2>/dev/null || true && \
    # CRITICAL: Final removal of system Python packages
    rm -rf /usr/lib/python3*/site-packages/pip 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/pip-* 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/setuptools 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/setuptools-* 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/pkg_resources 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/_distutils_hack 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/wheel 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/site-packages/wheel-* 2>/dev/null || true && \
    find /usr/lib -type d -name "pip-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/lib -type d -name "setuptools-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/lib -type d -name "wheel-*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    # Cleanup temp and cache
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    # Set permissions
    chown -R jupyter:jupyter /home/jupyter && \
    chmod 700 /home/jupyter/.config/gcloud && \
    chmod 700 /home/jupyter/.ssh && \
    chmod 644 /etc/pip.conf && \
    chmod 644 /etc/.pypirc && \
    chmod 600 /home/jupyter/.config/pip/pip.conf && \
    chmod 600 /home/jupyter/.pypirc

# Final Verification
RUN echo "============================================" && \
    echo "  FINAL VERIFICATION" && \
    echo "============================================" && \
    echo "R: $(R --version | head -1)" && \
    echo "Python: $(python3 --version)" && \
    echo "rstudioapi: $(R --slave -e "cat(as.character(packageVersion('rstudioapi')))")" && \
    echo "" && \
    echo "=== VENV Package Versions (SECURE) ===" && \
    /opt/venv/bin/pip --version && \
    /opt/venv/bin/pip show setuptools | grep -E "^(Name|Version):" && \
    /opt/venv/bin/pip show wheel | grep -E "^(Name|Version):" && \
    /opt/venv/bin/pip show cryptography | grep -E "^(Name|Version):" && \
    echo "" && \
    echo "=== SECURITY CHECK: System packages ===" && \
    echo "Checking /usr/lib for pip:" && \
    (ls -la /usr/lib/python3*/site-packages/pip* 2>/dev/null || echo "  CLEAN: No system pip found") && \
    echo "Checking /usr/lib for setuptools:" && \
    (ls -la /usr/lib/python3*/site-packages/setuptools* 2>/dev/null || echo "  CLEAN: No system setuptools found") && \
    echo "Checking /usr/lib for wheel:" && \
    (ls -la /usr/lib/python3*/site-packages/wheel* 2>/dev/null || echo "  CLEAN: No system wheel found") && \
    echo "" && \
    echo "=== Checking for .dist-info directories ===" && \
    (find /usr/lib -name "pip-*.dist-info" -type d 2>/dev/null | head -3 || echo "  CLEAN: No pip dist-info") && \
    (find /usr/lib -name "setuptools-*.dist-info" -type d 2>/dev/null | head -3 || echo "  CLEAN: No setuptools dist-info") && \
    (find /usr/lib -name "wheel-*.dist-info" -type d 2>/dev/null | head -3 || echo "  CLEAN: No wheel dist-info") && \
    echo "" && \
    jupyter kernelspec list && \
    echo "============================================"

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

# Runtime Configuration
EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="6.0" \
      description="GCP Workbench - R 4.1.0, rstudioapi 0.14, Alpine - All CVEs Fixed" \
      r.version="4.1.0" \
      rstudioapi.version="0.14" \
      security.patched="true"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]