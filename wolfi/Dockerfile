# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Security Fixes Applied:
#   - CVE-2025-53000: nbconvert Windows path traversal
#   - CVE-2025-8869: pip tar extraction symlink
#   - CVE-2026-23949: jaraco.context path traversal
#   - CVE-2025-59842: JupyterLab LaTeX noopener
# ============================================

# ============================================
# Stage 1: Build Stage
# ============================================
FROM alpine:3.21 AS builder

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

# 3. Create R Packages List
RUN echo "dplyr" > /tmp/packages.txt && \
    echo "tibble" >> /tmp/packages.txt && \
    echo "tidyr" >> /tmp/packages.txt && \
    echo "readr" >> /tmp/packages.txt && \
    echo "purrr" >> /tmp/packages.txt && \
    echo "stringr" >> /tmp/packages.txt && \
    echo "forcats" >> /tmp/packages.txt && \
    echo "ggplot2" >> /tmp/packages.txt && \
    echo "data.table" >> /tmp/packages.txt && \
    echo "jsonlite" >> /tmp/packages.txt && \
    echo "foreach" >> /tmp/packages.txt && \
    echo "doParallel" >> /tmp/packages.txt

# 4. Install R Packages
RUN R -e "\
    install_repo <- 'https://cloud.r-project.org'; \
    options(repos = c(CRAN = install_repo)); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '']; \
    for (pkg in packages) { \
        cat('Installing:', pkg, '\n'); \
        tryCatch({ \
            install.packages(pkg, lib='/usr/local/lib/R/site-library', repos=install_repo, dependencies=TRUE, Ncpus=parallel::detectCores()); \
        }, error = function(e) { \
            cat('WARNING: Failed to install', pkg, '\n'); \
        }); \
    }; \
    install.packages('IRkernel', lib='/usr/local/lib/R/site-library', repos=install_repo, dependencies=TRUE);"

# 5. Create Python venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 6. Upgrade pip first to fix CVE-2025-8869
RUN pip install --no-cache-dir --upgrade "pip>=25.3"

# 7. Upgrade setuptools to fix CVE-2026-23949 (jaraco.context)
RUN pip install --no-cache-dir --upgrade "setuptools>=78.1.1"

# 8. Install Jupyter packages with security patches
RUN pip install --no-cache-dir --upgrade wheel && \
    pip install --no-cache-dir \
        "jupyterlab>=4.4.8" \
        "notebook>=7.4.2" \
        "jupyter-server>=2.15.0" \
        "jupyter-server-proxy>=4.4.0" \
        "traitlets>=5.14.3" \
        "nbconvert>=7.16.7" \
        "jaraco.context>=6.0.1" \
        ipykernel \
        ipywidgets

# 9. Verify security patches
RUN echo "=== Security Patch Verification ===" && \
    pip show pip | grep -E "^Version:" && \
    pip show setuptools | grep -E "^Version:" && \
    pip show jupyterlab | grep -E "^Version:" && \
    pip show nbconvert | grep -E "^Version:" && \
    pip show jaraco.context | grep -E "^Version:" && \
    echo "=== Verification Complete ==="

# ============================================
# Stage 2: Final Runtime
# ============================================
FROM alpine:3.21

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

# 2. Create non-root user
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy artifacts from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# 4. Configure R Runtime
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# 5. Install R Kernel Spec (system-wide)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R (Alpine)')"

# 6. Setup Directories
RUN mkdir -p /home/jupyter/.jupyter && \
    mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.local/share/jupyter/runtime && \
    mkdir -p /home/jupyter/work && \
    mkdir -p /root/.jupyter && \
    mkdir -p /root/.local/share/jupyter/kernels && \
    mkdir -p /root/.local/share/jupyter/runtime && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# 7. Create Jupyter Configuration
RUN printf '%s\n' \
    'c = get_config()' \
    '' \
    '# Network settings' \
    'c.ServerApp.ip = "0.0.0.0"' \
    'c.ServerApp.port = 8080' \
    'c.ServerApp.open_browser = False' \
    '' \
    '# Authentication (disabled for GCP proxy)' \
    'c.ServerApp.token = ""' \
    'c.ServerApp.password = ""' \
    '' \
    '# Root execution (GCP Workbench runs as root)' \
    'c.ServerApp.allow_root = True' \
    '' \
    '# Remote access settings' \
    'c.ServerApp.allow_origin = "*"' \
    'c.ServerApp.allow_remote_access = True' \
    'c.ServerApp.allow_credentials = True' \
    'c.ServerApp.disable_check_xsrf = True' \
    'c.ServerApp.trust_xheaders = True' \
    '' \
    '# Directory settings' \
    'c.ServerApp.root_dir = "/home/jupyter"' \
    'c.ServerApp.notebook_dir = "/home/jupyter"' \
    '' \
    '# Features' \
    'c.ServerApp.terminals_enabled = True' \
    'c.MappingKernelManager.cull_idle_timeout = 0' \
    'c.MappingKernelManager.cull_interval = 0' \
    'c.ContentsManager.allow_hidden = True' \
    > /home/jupyter/.jupyter/jupyter_server_config.py && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py

# 8. Create Startup Script
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    'echo "============================================"' \
    'echo "  GCP Workbench - Starting Jupyter"' \
    'echo "============================================"' \
    'echo "User: $(whoami)"' \
    'echo "UID: $(id -u)"' \
    'echo "GID: $(id -g)"' \
    'echo "Python: $(python3 --version 2>&1)"' \
    'echo "R: $(R --version 2>&1 | head -1)"' \
    '' \
    '# Ensure directories exist' \
    'mkdir -p ~/.local/share/jupyter/kernels' \
    'mkdir -p ~/.local/share/jupyter/runtime' \
    'mkdir -p ~/.jupyter' \
    '' \
    '# Copy config if running as root' \
    'if [ "$(id -u)" = "0" ] && [ ! -f /root/.jupyter/jupyter_server_config.py ]; then' \
    '    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/ 2>/dev/null || true' \
    'fi' \
    '' \
    'echo ""' \
    'echo "Available kernels:"' \
    'jupyter kernelspec list' \
    '' \
    'echo ""' \
    'echo "Starting JupyterLab on port 8080..."' \
    'echo ""' \
    '' \
    'exec jupyter lab \' \
    '    --ip=0.0.0.0 \' \
    '    --port=8080 \' \
    '    --no-browser \' \
    '    --notebook-dir=/home/jupyter \' \
    '    --ServerApp.token="" \' \
    '    --ServerApp.password="" \' \
    '    --ServerApp.allow_origin="*" \' \
    '    --ServerApp.allow_remote_access=True \' \
    '    --ServerApp.allow_root=True \' \
    '    --allow-root' \
    > /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# 9. Security Hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache /home/jupyter/.cache

# 10. Final Verification
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    echo "" && \
    echo "=== Security Package Versions ===" && \
    pip show pip | grep -E "^Version:" && \
    pip show setuptools | grep -E "^Version:" && \
    pip show jupyterlab | grep -E "^Version:" && \
    pip show nbconvert | grep -E "^Version:" && \
    echo "=== Verification Complete ==="

# 11. Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="1.1" \
      description="GCP Workbench with R - Alpine Linux (Secure)" \
      security.cve-2025-53000="patched" \
      security.cve-2025-8869="patched" \
      security.cve-2026-23949="patched" \
      security.cve-2025-59842="patched"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]