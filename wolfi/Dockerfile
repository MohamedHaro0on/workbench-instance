# ============================================
# GCP Workbench - Maximum Security Version
# Based on Chainguard Wolfi (near-zero CVEs)
# ============================================

# ============================================
# Stage 1: Build R packages
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest AS r-builder

USER root

# Install build dependencies
RUN apk update && apk add --no-cache \
    R \
    R-dev \
    build-base \
    curl \
    wget \
    openssl-dev \
    curl-dev \
    libxml2-dev \
    fontconfig-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    harfbuzz-dev \
    fribidi-dev \
    cairo-dev \
    pango-dev \
    linux-headers \
    gfortran \
    pkgconf \
    git \
    icu-dev \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    readline \
    tiff-dev

# Configure R package repository
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 777 /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo 'options(Ncpus = parallel::detectCores())' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Copy packages list
COPY packages.txt /tmp/packages.txt

# Install R packages with error handling
RUN R -e "\
    options(warn = 1); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    cat('=== Installing R packages ===\n'); \
    cat('Packages:', paste(packages, collapse=', '), '\n\n'); \
    \
    for (pkg in packages) { \
        cat('\n>>> Installing:', pkg, '\n'); \
        tryCatch({ \
            install.packages(pkg, lib='/usr/local/lib/R/site-library', \
                           dependencies=TRUE, Ncpus=parallel::detectCores()); \
            cat('    [OK]', pkg, '\n'); \
        }, error = function(e) { \
            cat('    [WARN] Failed:', pkg, '-', conditionMessage(e), '\n'); \
        }); \
    }; \
    \
    cat('\n>>> Installing IRkernel\n'); \
    install.packages('IRkernel', lib='/usr/local/lib/R/site-library'); \
    \
    cat('\n=== Verification ===\n'); \
    success <- 0; fail <- 0; \
    for (pkg in c(packages, 'IRkernel')) { \
        if (requireNamespace(pkg, quietly=TRUE)) { \
            cat('[OK]    ', pkg, '\n'); success <- success + 1; \
        } else { \
            cat('[MISS]  ', pkg, '\n'); fail <- fail + 1; \
        } \
    }; \
    cat('\nSummary:', success, 'OK,', fail, 'missing\n')"

# ============================================
# Stage 2: Python Builder
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest AS python-builder

USER root

# Install Python and pip
RUN apk update && apk add --no-cache \
    python-3.12 \
    python-3.12-dev \
    py3.12-pip \
    py3.12-setuptools \
    py3.12-wheel

# Create virtual environment
RUN python3.12 -m venv /opt/jupyter-venv

# Install Python packages into virtual environment
RUN /opt/jupyter-venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/jupyter-venv/bin/pip install --no-cache-dir \
        jupyterlab==4.4.1 \
        notebook==7.4.2 \
        jupyter-server==2.15.0 \
        jupyter-server-proxy==4.4.0 \
        traitlets==5.14.3 \
        ipykernel \
        ipywidgets

# ============================================
# Stage 3: Final Runtime Image
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest

USER root

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV VIRTUAL_ENV=/opt/jupyter-venv
ENV PATH="/opt/jupyter-venv/bin:${PATH}"
ENV HOME=/home/jupyter

# Install minimal runtime packages
RUN apk update && apk add --no-cache \
    # R runtime
    R \
    # Python runtime
    python-3.12 \
    # Shell and init
    bash \
    tini \
    # Runtime libraries
    curl \
    libxml2 \
    fontconfig \
    freetype \
    libpng \
    libjpeg-turbo \
    tiff \
    harfbuzz \
    fribidi \
    cairo \
    pango \
    glib \
    libgit2 \
    libssh2 \
    icu \
    zlib \
    bzip2 \
    xz \
    pcre2 \
    readline \
    # For terminal
    ncurses \
    ncurses-terminfo-base \
    && rm -rf /var/cache/apk/*

# Create jupyter user (GCP Workbench requirement: uid 1000)
RUN addgroup -g 100 users 2>/dev/null || true && \
    adduser -D -u 1000 -G users -h /home/jupyter -s /bin/bash jupyter

# Copy Python virtual environment from builder
COPY --from=python-builder /opt/jupyter-venv /opt/jupyter-venv

# Copy R libraries from builder
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Configure R
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Install R kernel for Jupyter (system-wide)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R 4.x')"

# Create directories with proper ownership
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# Copy configuration files
COPY --chown=jupyter:users jupyter_server_config.py /home/jupyter/.jupyter/
COPY --chown=root:root start-jupyter.sh /usr/local/bin/

# Set permissions
RUN chmod +x /usr/local/bin/start-jupyter.sh && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py

# Security hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache 2>/dev/null || true

# Verification
RUN echo "=== Build Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    /opt/jupyter-venv/bin/jupyter --version && \
    /opt/jupyter-venv/bin/jupyter kernelspec list && \
    echo "=== Verification Complete ==="

# Expose port (GCP Workbench requirement)
EXPOSE 8080

# Switch to non-root user
USER jupyter
WORKDIR /home/jupyter

# Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]