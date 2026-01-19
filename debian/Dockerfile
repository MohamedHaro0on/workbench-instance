# ============================================
# GCP Workbench Compatible Image with R Support
# Security Hardened - Vulnerability Fixes v4
# Based on Debian Bookworm Slim
# ============================================

# ============================================
# Stage 1: Build R packages with Posit binaries
# ============================================
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Security: Add Debian security repository and update
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        curl \
        dirmngr \
        wget \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Add CRAN repository for latest R
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | \
    gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" > /etc/apt/sources.list.d/cran.list

# Install R and build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base \
        r-base-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff-dev \
        libjpeg-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libzmq3-dev \
        libcairo2-dev \
        libxt-dev \
        libgit2-dev \
        libssh2-1-dev \
        pkg-config \
        make \
        gcc \
        g++ \
        gfortran \
    && rm -rf /var/lib/apt/lists/*

# Configure Posit Package Manager for Debian Bookworm BINARY packages
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Copy packages list
COPY packages.txt /tmp/packages.txt

# Install R packages from Posit Package Manager
RUN R -e "\
    cat('=== Installing R packages from Posit Package Manager ===\n'); \
    cat('R version:', as.character(getRversion()), '\n'); \
    cat('Repo:', getOption('repos'), '\n'); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, lib='/usr/local/lib/R/site-library', Ncpus = parallel::detectCores()); \
    install.packages('IRkernel', lib='/usr/local/lib/R/site-library', Ncpus = parallel::detectCores()); \
    cat('\n=== Verification ===\n'); \
    failed <- character(0); \
    for (p in c(packages, 'IRkernel')) { \
        if (requireNamespace(p, quietly=TRUE)) { \
            cat('[OK]', p, '\n'); \
        } else { \
            cat('[FAIL]', p, '\n'); \
            failed <- c(failed, p); \
        } \
    }; \
    if (length(failed) > 0) { \
        stop('Failed to install: ', paste(failed, collapse=', ')); \
    }"

# ============================================
# Stage 2: Build secure versions of vulnerable packages
# ============================================
FROM debian:bookworm-slim AS security-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        wget \
        curl \
        libssl-dev \
        zlib1g-dev \
        libffi-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        liblzma-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libgdbm-dev \
        libnss3-dev \
        tk-dev \
        uuid-dev \
        xz-utils \
        libnghttp2-dev \
        libpsl-dev \
        libbrotli-dev \
        libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# Build curl from source (CVE-2025-0725, CVE-2025-9086)
RUN cd /tmp && \
    CURL_VERSION="8.11.1" && \
    wget -q https://curl.se/download/curl-${CURL_VERSION}.tar.gz && \
    tar -xzf curl-${CURL_VERSION}.tar.gz && \
    cd curl-${CURL_VERSION} && \
    ./configure --prefix=/usr/local/curl \
        --with-openssl \
        --with-nghttp2 \
        --enable-ipv6 \
        --disable-ldap \
        --disable-ldaps && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/curl-*

# Build SQLite from source (CVE-2025-7458)
RUN cd /tmp && \
    SQLITE_VERSION="3470200" && \
    wget -q https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_VERSION}.tar.gz && \
    tar -xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz && \
    cd sqlite-autoconf-${SQLITE_VERSION} && \
    ./configure --prefix=/usr/local/sqlite && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/sqlite-*

# Build Python from source (CVE-2025-13836)
RUN cd /tmp && \
    PYTHON_VERSION="3.12.8" && \
    wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --prefix=/usr/local/python \
        --enable-optimizations \
        --with-lto \
        --with-system-ffi \
        --with-ensurepip=install \
        --enable-shared \
        LDFLAGS="-Wl,-rpath,/usr/local/python/lib" && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/Python-*

# ============================================
# Stage 3: Final Runtime Image
# ============================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV PATH="/usr/local/python/bin:/usr/local/curl/bin:/usr/local/sqlite/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/python/lib:/usr/local/curl/lib:/usr/local/sqlite/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH="/usr/local/curl/lib/pkgconfig:/usr/local/sqlite/lib/pkgconfig:${PKG_CONFIG_PATH}"
ENV PIP_DEFAULT_TIMEOUT=100
ENV PIP_RETRIES=3

# PHASE 1: Remove vulnerable packages we don't need
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get remove -y --purge --allow-remove-essential \
        xdg-utils \
        xdg-user-dirs \
        zip \
        unzip \
        tcl \
        tcl8.6 \
        tk \
        tk8.6 \
        openldap-utils \
        ldap-utils \
        libldap-2.5-0 \
        libldap-common \
        libmbedtls14 \
        libmbedcrypto7 \
        libmbedx509-1 \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# PHASE 2: Install minimal runtime dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        dirmngr \
        libssl3 \
        libffi8 \
        libbz2-1.0 \
        libreadline8 \
        liblzma5 \
        libncurses6 \
        libgdbm6 \
        libnss3 \
        uuid-runtime \
        libnghttp2-14 \
        libpsl5 \
        libbrotli1 \
        libzstd1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add CRAN repository
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | \
    gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" > /etc/apt/sources.list.d/cran.list

# Install R and minimal runtime libs
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        r-base \
        libxml2 \
        libfontconfig1 \
        libfreetype6 \
        libpng16-16 \
        libjpeg62-turbo \
        libharfbuzz0b \
        libfribidi0 \
        libzmq5 \
        libcairo2 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libgit2-1.5 \
        libssh2-1 \
        bash \
        procps \
        tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# PHASE 3: Copy secure built packages
COPY --from=security-builder /usr/local/curl /usr/local/curl
COPY --from=security-builder /usr/local/sqlite /usr/local/sqlite
COPY --from=security-builder /usr/local/python /usr/local/python

# Create symlinks for Python
RUN ln -sf /usr/local/python/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/local/python/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/local/python/bin/pip3 /usr/local/bin/pip3 && \
    ln -sf /usr/local/python/bin/pip3 /usr/local/bin/pip && \
    ldconfig

# PHASE 4: Create jupyter user (GCP Workbench requirement)
RUN groupadd -g 100 users 2>/dev/null || true && \
    useradd -m -u 1000 -g users -s /bin/bash jupyter

# PHASE 5: Configure R
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Copy R libraries from builder stage
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# PHASE 6: Upgrade pip and install Python packages
RUN /usr/local/python/bin/pip3 install --no-cache-dir --upgrade \
        pip>=24.3.1 \
        setuptools>=75.6.0 \
        wheel>=0.45.1

# Install Jupyter packages
RUN /usr/local/python/bin/pip3 install --no-cache-dir \
        --timeout=300 \
        --retries=5 \
        jupyterlab==4.4.1 \
        notebook==7.4.2 \
        jupyter-server==2.15.0 \
        jupyter-server-proxy==4.4.0 \
        traitlets==5.14.3

# Install R kernel for Jupyter
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# PHASE 7: Create Jupyter configuration
RUN mkdir -p /home/jupyter/.jupyter

# Copy configuration files
COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# PHASE 8: Security hardening and cleanup
RUN apt-get update && \
    apt-get remove -y --purge \
        xdg-utils \
        xdg-user-dirs \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /root/.cache/pip /home/jupyter/.cache/pip

# PHASE 9: Set permissions
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.cache/R \
             /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py

# PHASE 10: Verify installations
RUN echo "=== VERIFICATION ===" && \
    /usr/local/python/bin/python3 --version && \
    /usr/local/curl/bin/curl --version | head -1 && \
    /usr/local/sqlite/bin/sqlite3 --version && \
    R --version | head -1 && \
    /usr/local/python/bin/jupyter kernelspec list && \
    echo "=== VERIFICATION COMPLETE ==="

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start Jupyter
CMD ["/usr/local/bin/start-jupyter.sh"]