# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Uses external scripts and config files
# Client: Vodafone - All requested packages
# ============================================

# Build arguments for version pinning
ARG ALPINE_VERSION=3.20
ARG GCLOUD_VERSION=485.0.0

# ============================================
# Stage 1: Builder
# ============================================
FROM alpine:${ALPINE_VERSION} AS builder

# Environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    R_LIBS_SITE=/usr/local/lib/R/site-library \
    R_LIBS_USER=/usr/local/lib/R/site-library \
    PYTHONDONTWRITEBYTECODE=1

# Copy package lists and scripts first (for caching)
COPY packages/ /tmp/packages/
COPY scripts/ /tmp/scripts/
COPY config/ /tmp/config/

# Make scripts executable
RUN chmod +x /tmp/scripts/*.sh 2>/dev/null || true && \
    chmod +x /tmp/scripts/*.R 2>/dev/null || true

# ============================================
# 1. Install ALL Build Dependencies
# ============================================
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    # Build essentials
    build-base gfortran linux-headers pkgconf autoconf automake libtool \
    # Core tools
    git bash wget curl coreutils findutils grep sed gawk \
    # R and Python
    R R-dev R-doc \
    python3 python3-dev py3-pip py3-wheel py3-setuptools \
    # Development libraries
    curl-dev openssl-dev libxml2-dev fontconfig-dev freetype-dev \
    libpng-dev jpeg-dev tiff-dev harfbuzz-dev fribidi-dev zeromq-dev \
    cairo-dev pango-dev libgit2-dev libssh2-dev icu-dev zlib-dev \
    bzip2-dev xz-dev pcre2-dev readline-dev libsodium-dev libx11-dev \
    libxt-dev openblas-dev lapack-dev fftw-dev util-linux-dev libuuid \
    # Additional for Google Cloud Python packages
    libffi-dev \
    && rm -rf /var/cache/apk/*

# ============================================
# 2. Setup R Library and Compiler Flags
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
# 3. Configure R
# ============================================
COPY config/Rprofile.site /usr/lib/R/etc/Rprofile.site

# ============================================
# 4. Install R Packages (using script)
# ============================================
RUN Rscript /tmp/scripts/install-r-packages.R

# ============================================
# 5. Setup Python Virtual Environment
# ============================================
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ============================================
# 6. Install Python Packages (using script)
# ============================================
RUN /tmp/scripts/install-python-packages.sh

# ============================================
# 7. Install Google Cloud SDK
# ============================================
ARG GCLOUD_VERSION
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
    /opt/google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=false && \
    rm -rf /opt/google-cloud-sdk/.install/.backup && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix 2>/dev/null || true

# ============================================
# 8. Apply CVE Mitigations
# ============================================
RUN /tmp/scripts/apply-cve-mitigations.sh

# ============================================
# 9. Cleanup R documentation to reduce size
# ============================================
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "help" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# 10. Verify All Client Packages
# ============================================
RUN echo "=== Verifying R Packages ===" && \
    R --slave -e "\
    .libPaths('/usr/local/lib/R/site-library'); \
    pkgs <- c('plyr','anomalize','foreach','tibbletime','doParallel','pbapply','dplyr','IRkernel'); \
    for(p in pkgs) { \
        if(requireNamespace(p, quietly=TRUE)) { \
            cat('OK:', p, as.character(packageVersion(p)), '\n'); \
        } else { \
            cat('MISSING:', p, '\n'); \
        } \
    }"

RUN echo "=== Verifying Python Packages ===" && \
    python3 -c "import jupyterlab; print('OK: jupyterlab', jupyterlab.__version__)" && \
    python3 -c "import notebook; print('OK: notebook', notebook.__version__)" && \
    python3 -c "import pandas; print('OK: pandas', pandas.__version__)" && \
    python3 -c "import pyarrow; print('OK: pyarrow', pyarrow.__version__)" && \
    python3 -c "import google.cloud.bigquery; print('OK: google-cloud-bigquery')" && \
    python3 -c "import google.cloud.bigquery_storage; print('OK: google-cloud-bigquery-storage')" && \
    python3 -c "import db_dtypes; print('OK: db-dtypes')" && \
    python3 -c "import virtualenv; print('OK: virtualenv', virtualenv.__version__)" && \
    python3 -c "import pipenv; print('OK: pipenv')" || echo "Some packages may be missing"

# ============================================
# Stage 2: Runtime (Minimal)
# ============================================
FROM alpine:${ALPINE_VERSION}

# Environment
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
    GOOGLE_CLOUD_PROJECT=""

# ============================================
# 1. Install Runtime Dependencies Only
# ============================================
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    # Core
    bash tini ca-certificates coreutils findutils grep sed gawk \
    # R runtime
    R \
    # Python runtime
    python3 libffi \
    # Network tools
    curl libcurl openssh-client \
    # Libraries (runtime only)
    libxml2 fontconfig freetype libpng jpeg tiff \
    harfbuzz fribidi zeromq cairo pango glib \
    libgit2 libssh2 icu-libs zlib bzip2 xz-libs \
    pcre2 readline libsodium openblas lapack \
    libgomp libgfortran ncurses ncurses-terminfo-base \
    fftw libuuid \
    # Git (client requested)
    git \
    && rm -rf /var/cache/apk/*

# ============================================
# 2. Create Non-Root User
# ============================================
RUN addgroup -g 1000 jupyter && \
    adduser -D -u 1000 -G jupyter -s /bin/bash -h /home/jupyter jupyter

# ============================================
# 3. Copy from Builder
# ============================================
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/google-cloud-sdk /opt/google-cloud-sdk
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /usr/lib/R/etc/Rprofile.site /usr/lib/R/etc/Rprofile.site

# ============================================
# 4. Setup Directories
# ============================================
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library && \
    mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/.config/gcloud \
             /home/jupyter/work \
             /root/.jupyter

# ============================================
# 5. Install R Kernel
# ============================================
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R 4.x')"

# ============================================
# 6. Copy Configuration Files
# ============================================
COPY config/jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh

RUN chmod +x /usr/local/bin/start-jupyter.sh

# ============================================
# 7. Security Hardening
# ============================================
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    chown -R jupyter:jupyter /home/jupyter && \
    chmod 700 /home/jupyter/.config/gcloud

# ============================================
# 8. Final Verification
# ============================================
RUN echo "=== Final Verification ===" && \
    echo "Python: $(python3 --version)" && \
    echo "R: $(R --version | head -1)" && \
    echo "Git: $(git --version)" && \
    echo "gcloud: $(gcloud --version | head -1)" && \
    jupyter --version && \
    jupyter kernelspec list

# ============================================
# 9. Health Check
# ============================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

# ============================================
# 10. Runtime Configuration
# ============================================
EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="4.0" \
      description="GCP Workbench with R, Python, Git, gcloud - Alpine (Hardened)" \
      org.opencontainers.image.title="GCP Workbench Alpine" \
      security.hardened="true"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]