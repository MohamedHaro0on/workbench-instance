# ============================================
# GCP Workbench Compatible Image with R Support
# Uses Posit Package Manager for BINARY packages
# Based on Debian Bookworm Slim (glibc-based, smaller footprint)
# Security hardened version
# ============================================

# ============================================
# Stage 1: Build R packages with Posit binaries
# ============================================
FROM debian:bookworm-20250428-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Security: Update system packages first
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        curl \
        dirmngr \
    && rm -rf /var/lib/apt/lists/*

# Add CRAN repository for latest R (Fixed key fetching)
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | \
    gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" \
    > /etc/apt/sources.list.d/cran.list

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

# Install R packages from Posit Package Manager (FAST binary install)
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
# Stage 2: Final Runtime Image (minimal)
# ============================================
FROM debian:bookworm-20250428-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library

# Pip configuration for better network handling
ENV PIP_DEFAULT_TIMEOUT=100
ENV PIP_RETRIES=3

# Security: Update and install minimal runtime dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        curl \
        dirmngr \
    && rm -rf /var/lib/apt/lists/*

# Add CRAN repository (Fixed key fetching)
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | \
    gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" \
    > /etc/apt/sources.list.d/cran.list

# Install ONLY runtime dependencies (no -dev packages)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        r-base \
        libcurl4 \
        libssl3 \
        libxml2 \
        libfontconfig1 \
        libfreetype6 \
        libpng16-16 \
        libtiff6 \
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

# Create jupyter user with GID 100 (users group) - required by GCP Workbench
RUN groupadd -g 100 users 2>/dev/null || true && \
    useradd -m -u 1000 -g users -s /bin/bash jupyter

# Create R library directory and configure
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Copy R libraries from builder stage
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# ============================================
# Install Python packages with timeout/retry handling
# ============================================

# Upgrade pip first for better timeout handling
RUN pip3 install --no-cache-dir --break-system-packages --upgrade pip

# Install jupyterlab (largest package) separately with extended timeout
RUN pip3 install --no-cache-dir --break-system-packages \
    --timeout=300 \
    --retries=5 \
    jupyterlab==4.4.1

# Install notebook and jupyter-server
RUN pip3 install --no-cache-dir --break-system-packages \
    --timeout=300 \
    --retries=5 \
    notebook==7.4.2 \
    jupyter-server==2.15.0

# Install remaining packages
RUN pip3 install --no-cache-dir --break-system-packages \
    --timeout=300 \
    --retries=5 \
    jupyter-server-proxy==4.4.0 \
    traitlets==5.14.3

# Install R kernel for Jupyter (system-wide)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# ============================================
# Verify installations - FIXED: use as.character() for packageVersion
# ============================================
RUN R --version && \
    jupyter kernelspec list && \
    R -e "cat('IRkernel:', as.character(packageVersion('IRkernel')), '\n')"

# Create Jupyter configuration directory
RUN mkdir -p /home/jupyter/.jupyter

# Create Jupyter configuration for GCP Workbench
COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py

# Create startup script for GCP Workbench
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# Security: Final cleanup and hardening
RUN rm -rf /tmp/* /var/tmp/* /root/.cache && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*

# Set proper permissions
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.cache/R \
             /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# Expose port 8080 (required by GCP Workbench)
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use tini as init system for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start Jupyter
CMD ["/usr/local/bin/start-jupyter.sh"]