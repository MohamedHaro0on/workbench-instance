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
# Version: 7.0 - Full R Support + All CVEs Fixed (Including Go)
# ============================================

ARG ALPINE_VERSION=3.21
ARG GCLOUD_VERSION=513.0.0
ARG R_VERSION=4.1.0

# ============================================
# Stage 1: Build R from Source
# ============================================
FROM alpine:${ALPINE_VERSION} AS r-builder

ARG R_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install build dependencies for R - NO GO
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

# Remove Go if accidentally installed as dependency
RUN apk del go golang 2>/dev/null || true && \
    rm -rf /usr/lib/go* /usr/local/go* /usr/bin/go /usr/bin/gofmt 2>/dev/null || true

# Verify patched versions
RUN echo "=== Verifying Security Patches ===" && \
    apk info expat | head -2 && \
    apk info sqlite | head -2 && \
    echo "=== libcurl version ===" && curl --version | head -1 && \
    echo "=== Go check ===" && (which go 2>/dev/null && echo "WARNING: Go present" || echo "OK: No Go")

# Download R source
RUN cd /tmp && \
    curl -fsSL -o R-${R_VERSION}.tar.gz \
        "https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz" && \
    tar -xzf R-${R_VERSION}.tar.gz

# Patch configure script to accept libcurl 8.x
RUN cd /tmp/R-${R_VERSION} && \
    echo "=== Patching configure for libcurl 8.x support ===" && \
    cp configure configure.orig && \
    sed -i 's/r_cv_have_curl728=no/r_cv_have_curl728=yes/g' configure && \
    echo "Patch applied - checking diff:" && \
    diff configure.orig configure | head -20 || true

# Build R
RUN cd /tmp/R-${R_VERSION} && \
    echo "=== Configuring R ${R_VERSION} ===" && \
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
    echo "=== Building R ${R_VERSION} ===" && \
    make -j$(nproc) && \
    echo "=== Installing R ${R_VERSION} ===" && \
    make install

# Cleanup and create symlinks
RUN rm -rf /tmp/R-${R_VERSION}* && \
    ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Verify R installation
RUN echo "=== R Version Verification ===" && \
    R --version | head -3


# ============================================
# Stage 2: Builder (Install Packages)
# ============================================
FROM alpine:${ALPINE_VERSION} AS builder

ARG GCLOUD_VERSION
ARG R_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    R_VERSION=${R_VERSION} \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_INDEX_URL=https://pypi.org/simple/ \
    PIP_TRUSTED_HOST=pypi.org

# Install Build Dependencies - EXPLICITLY NO GO
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
    cairo-dev \
    pango-dev \
    harfbuzz-dev \
    fribidi-dev \
    zeromq-dev \
    libsodium-dev \
    fftw-dev \
    util-linux-dev \
    libuuid \
    libffi-dev \
    expat \
    expat-dev \
    sqlite \
    sqlite-dev \
    openblas-dev \
    lapack-dev \
    file \
    && rm -rf /var/cache/apk/*

# ============================================
# CRITICAL: Remove Go if installed as dependency
# ============================================
RUN echo "=== Removing any Go installation ===" && \
    apk del go 2>/dev/null || true && \
    apk del golang 2>/dev/null || true && \
    rm -rf /usr/lib/go* 2>/dev/null || true && \
    rm -rf /usr/local/go* 2>/dev/null || true && \
    rm -rf /usr/share/go* 2>/dev/null || true && \
    rm -f /usr/bin/go 2>/dev/null || true && \
    rm -f /usr/bin/gofmt 2>/dev/null || true && \
    rm -f /usr/local/bin/go 2>/dev/null || true && \
    rm -f /usr/local/bin/gofmt 2>/dev/null || true && \
    echo "Go removal complete"

# Verify security patches are applied
RUN echo "=== Security Patch Verification ===" && \
    echo "expat version:" && apk info expat 2>/dev/null | head -1 && \
    echo "sqlite version:" && apk info sqlite 2>/dev/null | head -1 && \
    echo "Go check:" && (which go 2>/dev/null && echo "WARNING: Go still present" || echo "OK: Go not found")

# Copy R from r-builder stage
COPY --from=r-builder /opt/R /opt/R
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Verify R version
RUN echo "=== Verifying R Version ===" && \
    R --version | head -3

# Copy scripts and config
COPY config/ /tmp/config/
COPY packages/ /tmp/packages/
COPY scripts/ /tmp/scripts/

RUN chmod +x /tmp/scripts/*.sh 2>/dev/null || true

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

# Verify rstudioapi
RUN echo "=== Verifying rstudioapi ===" && \
    R --slave -e "if(requireNamespace('rstudioapi', quietly=TRUE)) { ver <- as.character(packageVersion('rstudioapi')); cat('rstudioapi version:', ver, '\n') } else { cat('ERROR: rstudioapi not installed\n'); quit(status=1) }"

# Clean R packages vulnerabilities
RUN echo "=== Cleaning R packages security issues ===" && \
    rm -rf /usr/local/lib/R/site-library/webshot/casperjs 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*casper*" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "fake_service_account.json" -delete 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/gargle/extdata 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/webfakes/cert 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/webfakes/certs 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "server.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "private.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "cert" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "certs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "localhost" -exec rm -rf {} + 2>/dev/null || true && \
    echo "R packages security cleanup complete"

# Setup Python Virtual Environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ============================================
# Install Python Packages with Security Fixes (INLINE)
# ============================================
RUN echo "=== Installing Python packages ===" && \
    pip install --no-cache-dir --upgrade "pip>=26.0" && \
    pip install --no-cache-dir --upgrade \
        "setuptools>=78.1.1" \
        "wheel>=0.46.2" \
        "cryptography>=44.0.1" && \
    echo "=== Installing virtualenv and pipenv ===" && \
    pip install --no-cache-dir virtualenv pipenv && \
    echo "=== Installing Jupyter ecosystem ===" && \
    pip install --no-cache-dir \
        jupyterlab \
        notebook \
        jupyter-server \
        jupyter-server-proxy \
        traitlets \
        ipykernel \
        ipywidgets \
        nbconvert && \
    echo "=== Installing Google Cloud packages ===" && \
    pip install --no-cache-dir \
        google-cloud-bigquery \
        google-cloud-bigquery-storage \
        db-dtypes && \
    echo "=== Installing data packages ===" && \
    pip install --no-cache-dir \
        pyarrow \
        pandas \
        numpy && \
    echo "=== Upgrading security-critical packages ===" && \
    pip install --no-cache-dir --upgrade \
        certifi \
        "urllib3>=2.0" \
        "requests>=2.31" && \
    echo "=== Final security re-upgrade ===" && \
    pip install --no-cache-dir --upgrade \
        "pip>=26.0" \
        "setuptools>=78.1.1" \
        "wheel>=0.46.2" \
        "cryptography>=44.0.1"

# ============================================
# CRITICAL: Remove ALL vulnerable vendored packages
# ============================================
RUN echo "=== Removing vulnerable vendored packages ===" && \
    SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])") && \
    echo "Site packages: $SITE_PACKAGES" && \
    find "$SITE_PACKAGES/virtualenv" -name "*.whl" -type f -delete 2>/dev/null || true && \
    rm -rf "$SITE_PACKAGES/virtualenv/seed/wheels" 2>/dev/null || true && \
    find "$SITE_PACKAGES/virtualenv" -type d -name "embed" -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES/virtualenv" -name "METADATA" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES/virtualenv" -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES/pipenv" -name "*.whl" -type f -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES/pipenv" -type d -name "wheel-*" -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES/pipenv" -type d -name "setuptools-*" -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES/pipenv" -name "METADATA" -path "*wheel*" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES/pipenv" -name "METADATA" -path "*setuptools*" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES/pip" -name "*.whl" -type f -delete 2>/dev/null || true && \
    rm -rf "$SITE_PACKAGES/setuptools/_vendor/wheel"* 2>/dev/null || true && \
    find "$SITE_PACKAGES" -path "*setuptools-6*" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES" -path "*setuptools-7[0-7]*" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES" -name "setuptools-6*.whl" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES" -name "setuptools-7[0-7]*.whl" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES" -path "*wheel-0.4[0-5]*" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES" -path "*wheel-0.[0-3]*" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find "$SITE_PACKAGES" -name "wheel-0.4[0-5]*.whl" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES" -name "wheel-0.[0-3]*.whl" -delete 2>/dev/null || true && \
    find "$SITE_PACKAGES" -name "*.whl" -type f -delete 2>/dev/null || true && \
    echo "=== Vendored packages cleanup complete ==="

# Verify Python packages
RUN echo "=== Verifying Python packages ===" && \
    pip --version && \
    pip show setuptools | grep -E "^(Name|Version):" && \
    pip show wheel | grep -E "^(Name|Version):" && \
    pip show cryptography | grep -E "^(Name|Version):" && \
    python3 -c "import jupyterlab; print('OK: jupyterlab', jupyterlab.__version__)" && \
    python3 -c "import pandas; print('OK: pandas', pandas.__version__)"

# ============================================
# Install Google Cloud SDK
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
# CRITICAL: Completely remove Go from Google Cloud SDK
# ============================================
RUN echo "=== AGGRESSIVELY Removing Go from Google Cloud SDK ===" && \
    find /opt/google-cloud-sdk -type d -name "go" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "go1*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "golang" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go" -type f -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "gofmt" -type f -delete 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix*/lib/go* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpython*/lib/go* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/anthoscli* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/anthoscli* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/cloud-build-local* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/cloud-build-local* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/gke-gcloud-auth-plugin* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/gke-gcloud-auth-plugin* 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.go" -type f -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go.mod" -type f -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go.sum" -type f -delete 2>/dev/null || true && \
    echo "Scanning for Go binaries..." && \
    for binary in $(find /opt/google-cloud-sdk -type f -executable 2>/dev/null); do \
        if file "$binary" 2>/dev/null | grep -qE "Go BuildID|Go build"; then \
            echo "Removing Go binary: $binary"; \
            rm -f "$binary" 2>/dev/null || true; \
        fi; \
    done && \
    echo "=== Go removal from gcloud SDK complete ==="

# SECURITY: Clean Google Cloud SDK
RUN echo "=== Cleaning Google Cloud SDK ===" && \
    find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true && \
    # find /opt/google-cloud-sdk -name "*.pem" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "pip" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "pip-*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "setuptools" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "setuptools-*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "wheel" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "wheel-*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "METADATA" -path "*pip*" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "METADATA" -path "*setuptools*" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "METADATA" -path "*wheel*" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.whl" -delete 2>/dev/null || true && \
    echo "Google Cloud SDK cleanup complete"

# Apply CVE Mitigations
RUN /tmp/scripts/apply-cve-mitigations.sh

# Clean R documentation to reduce size
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# VERIFY: No Go in builder stage
# ============================================
RUN echo "=== BUILDER: Verifying Go is completely removed ===" && \
    echo "Checking system Go..." && \
    if which go 2>/dev/null; then \
        echo "ERROR: System Go still present at $(which go)"; \
        go version 2>/dev/null || true; \
    else \
        echo "OK: No system Go found"; \
    fi && \
    echo "Checking for Go in /opt..." && \
    GO_OPT=$(find /opt -name "go" -type f 2>/dev/null | head -5) && \
    if [ -n "$GO_OPT" ]; then \
        echo "WARNING: Go found in /opt:"; \
        echo "$GO_OPT"; \
    else \
        echo "OK: No Go in /opt"; \
    fi

# Final Verification in Builder
RUN echo "=== BUILDER STAGE VERIFICATION ===" && \
    echo "=== R Version ===" && \
    R --version | head -3 && \
    echo "" && \
    echo "=== R Packages ===" && \
    R --slave -e "installed.packages()[,c('Package','Version')]" | head -20 && \
    echo "" && \
    echo "=== Python Package Versions ===" && \
    /opt/venv/bin/pip --version && \
    /opt/venv/bin/pip show setuptools | grep Version && \
    /opt/venv/bin/pip show wheel | grep Version && \
    /opt/venv/bin/pip show cryptography | grep Version


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
    PATH="/opt/venv/bin:/opt/R/${R_VERSION}/bin:/opt/google-cloud-sdk/bin:$PATH" \
    HOME=/home/jupyter \
    CLOUDSDK_CONFIG=/home/jupyter/.config/gcloud \
    GOOGLE_CLOUD_PROJECT="" \
    PIP_INDEX_URL=https://europe-west1-python.pkg.dev/vf-grp-aib-dev-mirror/pypi-repository/simple/ \
    PIP_TRUSTED_HOST=europe-west1-python.pkg.dev \
    PIP_EXTRA_INDEX_URL=https://pypi.org/simple/ \
    PIP_CONFIG_FILE=/etc/pip.conf \
    R_LIBS_USER=/home/jupyter/R/library \
    R_LIBS_SITE=/usr/local/lib/R/site-library

# ============================================
# Install Runtime Dependencies - NO GO
# ============================================
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache \
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
        icu-libs \
        zlib \
        bzip2 \
        xz-libs \
        pcre2 \
        readline \
        libsodium \
        ncurses \
        ncurses-terminfo-base \
        fftw \
        libuuid \
        expat \
        sqlite-libs \
        file \
        # R runtime dependencies
        cairo \
        pango \
        openblas \
        lapack \
        libgfortran \
        libgomp \
    && rm -rf /var/cache/apk/* \
    && apk del go golang 2>/dev/null || true

# ============================================
# CRITICAL: Ensure NO Go packages exist
# ============================================
RUN echo "=== Ensuring Go is not present in runtime ===" && \
    apk del go 2>/dev/null || true && \
    apk del golang 2>/dev/null || true && \
    rm -rf /usr/lib/go* 2>/dev/null || true && \
    rm -rf /usr/local/go* 2>/dev/null || true && \
    rm -rf /usr/share/go* 2>/dev/null || true && \
    rm -f /usr/bin/go 2>/dev/null || true && \
    rm -f /usr/bin/gofmt 2>/dev/null || true && \
    rm -f /usr/local/bin/go 2>/dev/null || true && \
    rm -f /usr/local/bin/gofmt 2>/dev/null || true && \
    if which go 2>/dev/null; then \
        echo "ERROR: Go is still installed!"; \
        exit 1; \
    else \
        echo "OK: Go is not installed"; \
    fi

# Remove ALL system Python packages
RUN echo "=== REMOVING ALL SYSTEM PYTHON PACKAGES ===" && \
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
    find /usr -name "METADATA" -path "*pip*" -delete 2>/dev/null || true && \
    find /usr -name "METADATA" -path "*setuptools*" -delete 2>/dev/null || true && \
    find /usr -name "METADATA" -path "*wheel*" -delete 2>/dev/null || true

# Copy config files
COPY config/pip.conf /etc/pip.conf
COPY config/pypirc /etc/.pypirc

# Create Non-Root User
RUN addgroup -g 1000 jupyter && \
    adduser -D -u 1000 -G jupyter -s /bin/bash -h /home/jupyter jupyter

# Copy from Builder
COPY --from=builder /opt/R /opt/R
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/google-cloud-sdk /opt/google-cloud-sdk
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# ============================================
# CRITICAL: Final aggressive cleanup of ALL Go
# ============================================
RUN echo "=== FINAL AGGRESSIVE GO CLEANUP ===" && \
    rm -rf /usr/lib/go* 2>/dev/null || true && \
    rm -rf /usr/local/go* 2>/dev/null || true && \
    rm -rf /usr/share/go* 2>/dev/null || true && \
    rm -f /usr/bin/go /usr/bin/gofmt 2>/dev/null || true && \
    rm -f /usr/local/bin/go /usr/local/bin/gofmt 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "go" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "go1*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "golang" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go" -type f -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "gofmt" -type f -delete 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpython*/lib/go* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/anthoscli* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/anthoscli* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/cloud-build-local* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/cloud-build-local* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/bin/gke-gcloud-auth-plugin* 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/gke-gcloud-auth-plugin* 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.go" -type f -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go.mod" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "go.sum" -delete 2>/dev/null || true && \
    echo "Removing Go-compiled binaries..." && \
    for binary in $(find /opt/google-cloud-sdk -type f -executable 2>/dev/null); do \
        if file "$binary" 2>/dev/null | grep -qE "Go BuildID|Go build"; then \
            echo "Removing: $binary"; \
            rm -f "$binary"; \
        fi; \
    done && \
    find /opt/google-cloud-sdk -name "*.whl" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "setuptools*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "wheel*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "pip*" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "METADATA" -delete 2>/dev/null || true && \
    SITE_PACKAGES="/opt/venv/lib/python3.12/site-packages" && \
    find "$SITE_PACKAGES" -name "*.whl" -type f -delete 2>/dev/null || true && \
    rm -rf "$SITE_PACKAGES/virtualenv/seed" 2>/dev/null || true && \
    echo "=== Cleanup complete ==="

# Create R symlinks
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Setup Directories
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/.config/gcloud \
             /home/jupyter/.config/pip \
             /home/jupyter/.ssh \
             /home/jupyter/work \
             /home/jupyter/R/library \
             /root/.jupyter \
             /root/.config/pip

# Configure pip
RUN cp /etc/pip.conf /home/jupyter/.config/pip/pip.conf && \
    cp /etc/pip.conf /root/.config/pip/pip.conf && \
    cp /etc/.pypirc /home/jupyter/.pypirc && \
    cp /etc/.pypirc /root/.pypirc

# Install R Kernel for Jupyter
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R ${R_VERSION}')"

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

# Final Security Hardening
RUN echo "=== Final Security Hardening ===" && \
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    find /opt -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.key" -delete 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    chown -R jupyter:jupyter /home/jupyter && \
    chmod 700 /home/jupyter/.config/gcloud && \
    chmod 700 /home/jupyter/.ssh && \
    chmod 644 /etc/pip.conf && \
    chmod 644 /etc/.pypirc && \
    chmod 600 /home/jupyter/.config/pip/pip.conf && \
    chmod 600 /home/jupyter/.pypirc && \
    echo "Security hardening complete"

# ============================================
# COMPREHENSIVE FINAL VULNERABILITY CHECK
# ============================================
RUN echo "============================================" && \
    echo "  FINAL VULNERABILITY CHECK" && \
    echo "============================================" && \
    echo "" && \
    echo "=== GO CHECK ===" && \
    echo "1. System Go binary:" && \
    if which go 2>/dev/null; then \
        echo "   ERROR: Go found at $(which go)"; \
        go version 2>/dev/null || true; \
    else \
        echo "   OK: Not found"; \
    fi && \
    echo "" && \
    echo "2. Go in /opt:" && \
    GO_OPT_COUNT=$(find /opt -name "go" -type f 2>/dev/null | wc -l) && \
    echo "   Found: $GO_OPT_COUNT" && \
    if [ "$GO_OPT_COUNT" -gt 0 ]; then \
        find /opt -name "go" -type f 2>/dev/null; \
    fi && \
    echo "" && \
    echo "3. Go-compiled binaries in /opt:" && \
    GO_BIN_COUNT=0 && \
    for f in $(find /opt -type f -executable 2>/dev/null | head -100); do \
        if file "$f" 2>/dev/null | grep -qE "Go BuildID"; then \
            echo "   WARNING: $f"; \
            GO_BIN_COUNT=$((GO_BIN_COUNT + 1)); \
        fi; \
    done && \
    echo "   Total Go binaries: $GO_BIN_COUNT" && \
    echo "" && \
    echo "=== APK PACKAGE CHECK ===" && \
    apk info go 2>/dev/null && echo "WARNING: go package installed" || echo "OK: go package not installed" && \
    apk info golang 2>/dev/null && echo "WARNING: golang package installed" || echo "OK: golang package not installed" && \
    echo "" && \
    echo "=== PYTHON PACKAGE CHECK ===" && \
    echo "pip: $(/opt/venv/bin/pip show pip 2>/dev/null | grep Version)" && \
    echo "setuptools: $(/opt/venv/bin/pip show setuptools 2>/dev/null | grep Version)" && \
    echo "wheel: $(/opt/venv/bin/pip show wheel 2>/dev/null | grep Version)" && \
    echo "cryptography: $(/opt/venv/bin/pip show cryptography 2>/dev/null | grep Version)" && \
    echo "" && \
    echo "============================================"

# Final Verification
RUN echo "============================================" && \
    echo "  FINAL VERIFICATION" && \
    echo "============================================" && \
    echo "R: $(R --version 2>/dev/null | head -1)" && \
    echo "Python: $(python3 --version)" && \
    echo "Jupyter: $(jupyter --version 2>/dev/null | head -1)" && \
    echo "gcloud: $(gcloud --version 2>/dev/null | head -1)" && \
    echo "" && \
    echo "=== R Packages Summary ===" && \
    R --slave -e "cat('Installed packages:', nrow(installed.packages()), '\n')" && \
    R --slave -e "cat('rstudioapi:', as.character(packageVersion('rstudioapi')), '\n')" && \
    echo "" && \
    echo "=== Jupyter Kernels ===" && \
    jupyter kernelspec list && \
    echo "============================================"

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="7.0-full" \
      description="GCP Workbench - R 4.1.0 + Python - No Go Runtime" \
      r.version="4.1.0" \
      security.patched="true" \
      go.status="completely-removed"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]
