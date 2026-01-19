# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# No glibc = No glibc CVEs
# ============================================

# ============================================
# Stage 1: Build Stage
# ============================================
FROM alpine:3.20 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install all build dependencies including those needed for tidyverse
RUN apk update && apk upgrade && apk add --no-cache \
    # Build essentials
    build-base \
    gfortran \
    linux-headers \
    pkgconf \
    git \
    bash \
    wget \
    curl \
    # R and development
    R \
    R-dev \
    R-doc \
    # Python
    python3 \
    python3-dev \
    py3-pip \
    py3-wheel \
    py3-setuptools \
    # Libraries for R packages (tidyverse dependencies)
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
    # Additional dependencies for tidyverse/data packages
    icu-dev \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    readline-dev \
    libsodium-dev \
    # For some R packages that need X11
    libx11-dev \
    libxt-dev \
    # For parallel processing packages
    openblas-dev \
    lapack-dev

# Configure R to use multiple cores and set CRAN mirror
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo 'options(Ncpus = parallel::detectCores())' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Copy packages list
COPY packages.txt /tmp/packages.txt

# Install R packages with better error handling
RUN R -e "\
    options(warn = 1); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    cat('Installing packages:', paste(packages, collapse=', '), '\n'); \
    \
    # Install packages one by one for better error tracking \
    for (pkg in packages) { \
        cat('\n=== Installing:', pkg, '===\n'); \
        tryCatch({ \
            install.packages(pkg, lib='/usr/local/lib/R/site-library', \
                           dependencies=TRUE, Ncpus=parallel::detectCores()); \
        }, error = function(e) { \
            cat('WARNING: Failed to install', pkg, ':', conditionMessage(e), '\n'); \
        }); \
    }; \
    \
    # Install IRkernel \
    cat('\n=== Installing IRkernel ===\n'); \
    install.packages('IRkernel', lib='/usr/local/lib/R/site-library'); \
    \
    # Verify installations \
    cat('\n=== Verification ===\n'); \
    for (pkg in c(packages, 'IRkernel')) { \
        if (requireNamespace(pkg, quietly=TRUE)) { \
            cat('[OK]', pkg, '\n'); \
        } else { \
            cat('[MISSING]', pkg, '\n'); \
        } \
    }"

# Create Python virtual environment for cleaner package management
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install Python packages
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
        jupyterlab==4.4.1 \
        notebook==7.4.2 \
        jupyter-server==2.15.0 \
        jupyter-server-proxy==4.4.0 \
        traitlets==5.14.3 \
        ipykernel \
        ipywidgets

# ============================================
# Stage 2: Final Runtime
# ============================================
FROM alpine:3.20

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/home/jupyter

# Install only runtime dependencies (no -dev packages)
RUN apk update && apk upgrade && apk add --no-cache \
    # Core
    bash \
    tini \
    ca-certificates \
    # R runtime
    R \
    # Python runtime
    python3 \
    # Runtime libraries (non-dev versions)
    curl \
    libcurl \
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
    # For terminal support
    ncurses \
    ncurses-terminfo-base \
    && rm -rf /var/cache/apk/*

# Create jupyter user (GCP Workbench requirement)
RUN addgroup -g 100 users && \
    adduser -D -u 1000 -G users -s /bin/bash jupyter

# Copy Python virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Copy R libraries from builder
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Configure R
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Install R kernel for Jupyter (as root, system-wide)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R 4.x')"

# Setup directories
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# Copy configuration files
COPY --chown=jupyter:users jupyter_server_config.py /home/jupyter/.jupyter/
COPY --chown=root:root start-jupyter.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-jupyter.sh && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py

# Security hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache

# Verify installations
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    echo "=== Verification Complete ==="

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]