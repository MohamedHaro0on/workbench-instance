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
# Version: 4.8 - R 4.1.0 + Zero Vulnerabilities
# ============================================

ARG ALPINE_VERSION=3.18
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
RUN apk update && apk add --no-cache \
    build-base \
    gfortran \
    linux-headers \
    bash \
    coreutils \
    curl \
    wget \
    xz \
    # R build dependencies
    readline-dev \
    icu-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    zlib-dev \
    curl-dev \
    libpng-dev \
    jpeg-dev \
    tiff-dev \
    cairo-dev \
    pango-dev \
    openblas-dev \
    lapack-dev \
    libxml2-dev \
    # For building with X11 support (optional)
    libx11-dev \
    libxt-dev \
    # Java (optional, for rJava)
    # openjdk11-jdk \
    && rm -rf /var/cache/apk/*

# Download and build R 4.1.0
RUN cd /tmp && \
    curl -fsSL -o R-${R_VERSION}.tar.gz \
        "https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz" && \
    tar -xzf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
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
        --with-libcurl \
        --with-pcre2 \
        CFLAGS="-O2 -fPIC" \
        CXXFLAGS="-O2 -fPIC" \
        FFLAGS="-O2" \
        FCFLAGS="-O2" && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/R-${R_VERSION}*

# Create symlinks
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Verify R installation
RUN R --version | head -3

# ============================================
# Stage 2: Builder (Install Packages)
# ============================================
FROM alpine:${ALPINE_VERSION} AS builder

ARG GCLOUD_VERSION
ARG R_VERSION

# BUILD TIME: Use official PyPI
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
    python3 \
    python3-dev \
    py3-pip \
    py3-wheel \
    py3-setuptools \
    # R runtime and build dependencies
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
    && rm -rf /var/cache/apk/*

# ============================================
# 2. Copy R from r-builder stage
# ============================================
COPY --from=r-builder /opt/R /opt/R
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Verify R version is 4.1.0
RUN echo "=== Verifying R Version ===" && \
    R --version | head -3 && \
    R_VER=$(R --version | head -1 | grep -oP '\d+\.\d+\.\d+') && \
    echo "Detected R version: $R_VER" && \
    if [ "$R_VER" != "${R_VERSION}" ]; then \
        echo "ERROR: Expected R ${R_VERSION}, got $R_VER"; \
        exit 1; \
    fi && \
    echo "R version verified: ${R_VERSION}"

# ============================================
# 3. Copy scripts and config
# ============================================
COPY config/ /tmp/config/
COPY packages/ /tmp/packages/
COPY scripts/ /tmp/scripts/

RUN chmod +x /tmp/scripts/*.sh 2>/dev/null || true && \
    chmod +x /tmp/scripts/*.R 2>/dev/null || true

# ============================================
# 4. Setup R Library and Compiler Flags
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
# 5. Configure R
# ============================================
COPY config/Rprofile.site /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site

# ============================================
# 6. Install R Packages (from r-packages.txt)
# ============================================
RUN Rscript /tmp/scripts/install-r-packages.R

# ============================================
# 7. Verify rstudioapi version
# ============================================
RUN echo "=== Verifying rstudioapi ===" && \
    R --slave -e "if(requireNamespace('rstudioapi', quietly=TRUE)) { \
        ver <- as.character(packageVersion('rstudioapi')); \
        cat('rstudioapi version:', ver, '\n'); \
        if(ver != '0.14') { \
            cat('WARNING: Expected 0.14, got', ver, '\n'); \
        } else { \
            cat('OK: rstudioapi 0.14 installed\n'); \
        } \
    } else { \
        cat('ERROR: rstudioapi not installed\n'); \
        quit(status=1); \
    }"

# ============================================
# 8. SECURITY: Clean R packages vulnerabilities
# ============================================
RUN echo "=== Cleaning R packages security issues ===" && \
    rm -rf /usr/local/lib/R/site-library/webshot/casperjs 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*casper*" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "fake_service_account.json" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*fake*credential*" -delete 2>/dev/null || true && \
    rm -rf /usr/local/lib/R/site-library/gargle/extdata 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.key" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -name "*.pem" -type f -exec grep -l "PRIVATE KEY" {} \; -delete 2>/dev/null || true && \
    echo "R packages security cleanup complete"

# ============================================
# 9. Setup Python Virtual Environment
# ============================================
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ============================================
# 10. Install Python Packages
# ============================================
RUN /tmp/scripts/install-python-packages.sh

# ============================================
# 11. Install Google Cloud SDK
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
# 12. SECURITY: Clean Google Cloud SDK
# ============================================
RUN echo "=== Cleaning Google Cloud SDK security issues ===" && \
    find /opt/google-cloud-sdk -name "*.key" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.pem" -type f -exec grep -l "PRIVATE KEY" {} \; -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "test" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "package.json" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    rm -f /opt/google-cloud-sdk/bin/gcloud-crc32c 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/.install/.backup 2>/dev/null || true && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true && \
    find /opt/google-cloud-sdk -name "*.pyc" -delete 2>/dev/null || true && \
    find /opt/google-cloud-sdk -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    echo "Google Cloud SDK security cleanup complete"

# ============================================
# 13. Apply CVE Mitigations
# ============================================
RUN /tmp/scripts/apply-cve-mitigations.sh

# ============================================
# 14. Cleanup
# ============================================
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "help" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# 15. Final Verification
# ============================================
RUN echo "=== FINAL BUILD VERIFICATION ===" && \
    echo "" && \
    echo "R Version:" && \
    R --version | head -1 && \
    echo "" && \
    echo "rstudioapi:" && \
    R --slave -e "cat('rstudioapi:', as.character(packageVersion('rstudioapi')), '\n')" && \
    echo "" && \
    echo "Key Packages:" && \
    R --slave -e ".libPaths('/usr/local/lib/R/site-library'); \
        pkgs <- c('rstudioapi','dplyr','ggplot2','tidyverse','forecast','anomalize','tibbletime','IRkernel'); \
        for(p in pkgs) { \
            if(requireNamespace(p, quietly=TRUE)) { \
                cat('OK:', p, as.character(packageVersion(p)), '\n') \
            } else { \
                cat('MISSING:', p, '\n') \
            } \
        }"


# ============================================
# Stage 3: Runtime (Minimal)
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
# 2. Copy config files
# ============================================
COPY config/pip.conf /etc/pip.conf
COPY config/pypirc /etc/.pypirc

# ============================================
# 3. Create Non-Root User
# ============================================
RUN addgroup -g 1000 jupyter && \
    adduser -D -u 1000 -G jupyter -s /bin/bash -h /home/jupyter jupyter

# ============================================
# 4. Copy from Builder
# ============================================
COPY --from=builder /opt/R /opt/R
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/google-cloud-sdk /opt/google-cloud-sdk
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Create R symlinks
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

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
# 6. Configure pip
# ============================================
RUN cp /etc/pip.conf /home/jupyter/.config/pip/pip.conf && \
    cp /etc/pip.conf /root/.config/pip/pip.conf && \
    cp /etc/.pypirc /home/jupyter/.pypirc && \
    cp /etc/.pypirc /root/.pypirc

# ============================================
# 7. Install R Kernel
# ============================================
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R 4.1.0')"

# ============================================
# 8. Copy Configuration Files
# ============================================
COPY config/jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh

RUN chmod +x /usr/local/bin/start-jupyter.sh

# ============================================
# 9. Configure Git
# ============================================
RUN git config --system init.defaultBranch main && \
    git config --system core.editor "vi" && \
    git config --system credential.helper store && \
    git config --system --add safe.directory '*'

# ============================================
# 10. Final Security Hardening
# ============================================
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    find /opt /usr/local/lib/R -type d -name "casperjs" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt /usr/local/lib/R -name "*casper*" -delete 2>/dev/null || true && \
    find /opt -name "*.key" -delete 2>/dev/null || true && \
    find /opt /usr/local/lib/R -name "*fake*" -delete 2>/dev/null || true && \
    find /opt -type d -name "dummyserver" -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
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
    echo "=== R ===" && \
    R --version | head -1 && \
    echo "rstudioapi: $(R --slave -e "cat(as.character(packageVersion('rstudioapi')))")" && \
    echo "" && \
    echo "=== Python ===" && \
    python3 --version && \
    pip --version && \
    echo "" && \
    echo "=== Jupyter Kernels ===" && \
    jupyter kernelspec list && \
    echo "" && \
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
      version="4.8" \
      description="GCP Workbench - R 4.1.0, rstudioapi 0.14, Alpine (Zero Vulnerabilities)" \
      r.version="4.1.0" \
      rstudioapi.version="0.14" \
      org.opencontainers.image.title="GCP Workbench Alpine R 4.1.0" \
      org.opencontainers.image.vendor="Vodafone" \
      security.hardened="true"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]