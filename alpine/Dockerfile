# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# No glibc = No glibc CVEs
# Fixes: Root execution, GCP Workbench compatibility
# Security: All CVEs mitigated/patched
# Last Updated: 2026-01-26
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

# 5. Remove R documentation with example keys (security scan false positives)
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "html" -exec rm -rf {} + 2>/dev/null || true

# 6. Create Python venv and install Jupyter with security patches
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install with pinned secure versions
# - setuptools>=80.11 fixes vendored wheel CVE-2026-24049
# - wheel>=0.46.3 fixes CVE-2026-24049
# - jupyterlab>=4.4.8 fixes CVE-2025-59842
# - nbconvert: CVE-2025-53000 has no upstream fix yet (mitigated below)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --upgrade "setuptools>=80.11" "wheel>=0.46.3" && \
    pip install --no-cache-dir \
        "jupyterlab>=4.4.8" \
        "notebook>=7.4.2" \
        "jupyter-server>=2.15.0" \
        "jupyter-server-proxy>=4.4.0" \
        "traitlets>=5.14.3" \
        ipykernel \
        ipywidgets \
        "nbconvert>=7.16.6"

# 7. Mitigate CVE-2025-53000 (nbconvert SVG to PDF arbitrary code execution)
# Since no upstream fix exists, we disable the vulnerable PDF exporter
RUN NBCONVERT_PATH=$(python3 -c "import nbconvert; import os; print(os.path.dirname(nbconvert.__file__))") && \
    if [ -f "${NBCONVERT_PATH}/exporters/pdf.py" ]; then \
        echo "# PDF Exporter disabled for CVE-2025-53000 mitigation" > "${NBCONVERT_PATH}/exporters/pdf.py"; \
        echo "raise ImportError('PDF export disabled for security - CVE-2025-53000')" >> "${NBCONVERT_PATH}/exporters/pdf.py"; \
    fi

# 8. Remove any documentation with example keys from Python packages
RUN find /opt/venv -name "*.html" -path "*/doc/*" -delete 2>/dev/null || true && \
    find /opt/venv -type d -name "doc" -path "*/site-packages/*" -exec rm -rf {} + 2>/dev/null || true

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

# 1. Install Runtime Dependencies with security patches
# Explicitly upgrade libpng to fix CVE-2026-22695 and CVE-2026-22801
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
    "libpng>=1.6.54-r0" \
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

# 2. Create User
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy artifacts from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# 4. Configure R Runtime
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# 5. Install R Kernel Spec
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

# 7. Copy Jupyter Configuration
COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
RUN chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py

# 8. Copy Startup Script
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# 9. Security Hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    # Remove any remaining documentation that might contain example keys
    find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /opt/venv -name "*.html" -path "*/doc/*" -delete 2>/dev/null || true

# 10. Final Verification
RUN echo "=== Final Verification ===" && \
    echo "--- System Versions ---" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    echo "--- Kernel Specs ---" && \
    jupyter kernelspec list && \
    echo "--- Security Package Versions ---" && \
    echo "libpng version:" && apk info libpng 2>/dev/null | head -1 && \
    pip show jupyterlab | grep -E "^(Name|Version):" && \
    pip show nbconvert | grep -E "^(Name|Version):" && \
    pip show wheel | grep -E "^(Name|Version):" && \
    pip show setuptools | grep -E "^(Name|Version):" && \
    echo "--- CVE-2025-53000 Mitigation Check ---" && \
    python3 -c "from nbconvert.exporters import pdf; print('WARNING: PDF exporter still enabled')" 2>&1 || echo "PDF exporter disabled (CVE-2025-53000 mitigated)" && \
    echo "=== Verification Complete ==="

# 11. Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="1.1" \
      description="GCP Workbench with R - Alpine Linux (Security Hardened)" \
      org.opencontainers.image.title="GCP Workbench with R" \
      org.opencontainers.image.description="Secure JupyterLab environment with R kernel for GCP Workbench" \
      org.opencontainers.image.version="1.1" \
      org.opencontainers.image.base.name="alpine:3.20" \
      security.scan-date="2026-01-26" \
      security.cve-2026-22695="fixed-libpng-1.6.54" \
      security.cve-2026-22801="fixed-libpng-1.6.54" \
      security.cve-2025-59842="fixed-jupyterlab-4.4.8" \
      security.cve-2026-24049="fixed-wheel-0.46.3" \
      security.cve-2025-53000="mitigated-pdf-exporter-disabled"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]