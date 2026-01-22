# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# No glibc = No glibc CVEs
# Fixes: Root execution, GCP Workbench compatibility
# Security: CVE-2025-53000 mitigated
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

# 5. Create Python venv and install Jupyter with patched nbconvert
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
        ipywidgets \
        "nbconvert>=7.16.6"

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
    rm -rf /tmp/* /var/tmp/* /root/.cache

# 10. Final Verification
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    pip show nbconvert | grep Version && \
    echo "=== Verification Complete ==="

# 11. Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="1.0" \
      description="GCP Workbench with R - Alpine Linux" \
      security.cve-2025-53000="patched"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]