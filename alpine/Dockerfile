# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# No glibc = No glibc CVEs
# Fixes: Root execution, GCP Workbench compatibility
# ============================================

# ============================================
# Stage 1: Build Stage
# ============================================
FROM alpine:3.20 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 1. Install Build Dependencies
RUN apk update && apk upgrade && apk add --no-cache \
    build-base \
    gfortran \
    linux-headers \
    pkgconf \
    git \
    bash \
    wget \
    curl \
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
    lapack-dev

# 2. Configure R directories
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library

# 3. Create R Packages List (Inlined for stability)
RUN echo "# Core data manipulation" > /tmp/packages.txt && \
    echo "dplyr" >> /tmp/packages.txt && \
    echo "tibble" >> /tmp/packages.txt && \
    echo "tidyr" >> /tmp/packages.txt && \
    echo "readr" >> /tmp/packages.txt && \
    echo "purrr" >> /tmp/packages.txt && \
    echo "stringr" >> /tmp/packages.txt && \
    echo "forcats" >> /tmp/packages.txt && \
    echo "# Visualization" >> /tmp/packages.txt && \
    echo "ggplot2" >> /tmp/packages.txt && \
    echo "# Data handling" >> /tmp/packages.txt && \
    echo "data.table" >> /tmp/packages.txt && \
    echo "jsonlite" >> /tmp/packages.txt && \
    echo "# Parallel processing" >> /tmp/packages.txt && \
    echo "foreach" >> /tmp/packages.txt && \
    echo "doParallel" >> /tmp/packages.txt

# 4. Install R Packages
RUN R -e " \
    install_repo <- 'https://cloud.r-project.org'; \
    options(repos = c(CRAN = install_repo)); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    cat('Installing packages:', paste(packages, collapse=', '), '\n'); \
    for (pkg in packages) { \
        cat('\n=== Installing:', pkg, '===\n'); \
        tryCatch({ \
            install.packages(pkg, \
                lib='/usr/local/lib/R/site-library', \
                repos=install_repo, \
                dependencies=TRUE, \
                Ncpus=parallel::detectCores()); \
        }, error = function(e) { \
            cat('WARNING: Failed to install', pkg, ':', conditionMessage(e), '\n'); \
        }); \
    }; \
    cat('\n=== Installing IRkernel ===\n'); \
    install.packages('IRkernel', \
        lib='/usr/local/lib/R/site-library', \
        repos=install_repo, \
        dependencies=TRUE); \
    cat('\n=== Verification ===\n'); \
    for (pkg in c(packages, 'IRkernel')) { \
        if (requireNamespace(pkg, quietly=TRUE)) { \
            cat('[OK]', pkg, '\n'); \
        } else { \
            cat('[MISSING]', pkg, '\n'); \
        } \
    }"

# 5. Create Python venv and install Jupyter
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

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

# 1. Install Runtime Dependencies
RUN apk update && apk upgrade && apk add --no-cache \
    bash \
    tini \
    ca-certificates \
    R \
    python3 \
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
    ncurses \
    ncurses-terminfo-base \
    && rm -rf /var/cache/apk/*

# 2. Create User (useful for file ownership)
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy artifacts from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# 4. Configure R Runtime
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# 5. Install R Kernel Spec (system-wide for root access)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R (Alpine)')"

# 6. Setup Directories & Permissions (for both jupyter user AND root)
RUN mkdir -p /home/jupyter/.jupyter \
    /home/jupyter/.local/share/jupyter/kernels \
    /home/jupyter/.local/share/jupyter/runtime \
    /home/jupyter/work \
    /root/.jupyter \
    /root/.local/share/jupyter/kernels \
    /root/.local/share/jupyter/runtime && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# 7. Generate Jupyter Configuration (CRITICAL: allow_root = True)
RUN echo "# Jupyter Server Configuration for GCP Workbench" > /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c = get_config()" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Network settings" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Authentication (disabled for GCP proxy)" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.token = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# CRITICAL: Allow root execution (GCP Workbench runs as root)" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Remote access settings" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_credentials = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.disable_check_xsrf = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.trust_xheaders = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Directory settings" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.root_dir = '/home/jupyter'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.notebook_dir = '/home/jupyter'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Features" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.terminals_enabled = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.MappingKernelManager.cull_idle_timeout = 0" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.MappingKernelManager.cull_interval = 0" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ContentsManager.allow_hidden = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py

# 8. Create Startup Script (CRITICAL: --allow-root flag)
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  GCP Workbench - Starting Jupyter"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "User: $(whoami)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "UID: $(id -u)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "GID: $(id -g)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Home: $HOME"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Python: $(python3 --version 2>&1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "R: $(R --version 2>&1 | head -1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo '# Ensure directories exist for current user' >> /usr/local/bin/start-jupyter.sh && \
    echo 'mkdir -p ~/.local/share/jupyter/kernels' >> /usr/local/bin/start-jupyter.sh && \
    echo 'mkdir -p ~/.local/share/jupyter/runtime' >> /usr/local/bin/start-jupyter.sh && \
    echo 'mkdir -p ~/.jupyter' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo '# Copy config if running as root and config not present' >> /usr/local/bin/start-jupyter.sh && \
    echo 'if [ "$(id -u)" = "0" ] && [ ! -f /root/.jupyter/jupyter_server_config.py ]; then' >> /usr/local/bin/start-jupyter.sh && \
    echo '    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/ 2>/dev/null || true' >> /usr/local/bin/start-jupyter.sh && \
    echo 'fi' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Available kernels:"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'jupyter kernelspec list' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Starting JupyterLab on port 8080..."' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo '# Start Jupyter with all necessary flags' >> /usr/local/bin/start-jupyter.sh && \
    echo 'exec jupyter lab \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ip=0.0.0.0 \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --port=8080 \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --no-browser \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --notebook-dir=/home/jupyter \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ServerApp.token="" \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ServerApp.password="" \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ServerApp.allow_origin="*" \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ServerApp.allow_remote_access=True \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --ServerApp.allow_root=True \' >> /usr/local/bin/start-jupyter.sh && \
    echo '    --allow-root' >> /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# 9. Security Hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache

# 10. Final Verification
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    cat /home/jupyter/.jupyter/jupyter_server_config.py | grep allow_root && \
    echo "=== Verification Complete ==="

# 11. Health Check for GCP
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

# NOTE: USER directive kept for security best practice
# GCP Workbench will override to root, but --allow-root handles that
USER jupyter
WORKDIR /home/jupyter

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]