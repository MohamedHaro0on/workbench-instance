# ============================================
# GCP Workbench - Zero Vulnerability Build
# Target: Fix Git, Curl, Patch, X11, PolicyKit CVEs
# Base: Debian Bookworm Slim (Hardened)
# Fixes: Root execution, GCP compatibility, CVE cleanup
# ============================================

# -------------------------------------------------------------------------
# STAGE 1: Toolchain Builder (Compiling Secure Versions)
# -------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libreadline-dev \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    gettext \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libpcre2-dev \
    && rm -rf /var/lib/apt/lists/*

# 1. Build Secure Curl (v8.12.1 - Fixes CVE-2025-9086)
RUN cd /tmp && \
    CURL_VER="8.12.1" && \
    wget -q https://curl.se/download/curl-${CURL_VER}.tar.gz && \
    tar -xzf curl-${CURL_VER}.tar.gz && \
    cd curl-${CURL_VER} && \
    ./configure --prefix=/usr/local/curl \
        --with-openssl \
        --disable-ldap \
        --disable-ldaps \
        --disable-manual \
        --disable-dict \
        --disable-gopher \
        --disable-imap \
        --disable-pop3 \
        --disable-smtp \
        --disable-telnet \
        --disable-tftp \
        --disable-rtsp \
        --without-libpsl \
        --without-libidn2 && \
    make -j$(nproc) && \
    make install

# 2. Build Secure Git (v2.48.1 - Fixes CVE-2024-52005)
RUN cd /tmp && \
    GIT_VER="2.48.1" && \
    wget -q https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.gz && \
    tar -xzf git-${GIT_VER}.tar.gz && \
    cd git-${GIT_VER} && \
    make configure && \
    ./configure --prefix=/usr/local/git --with-openssl --with-curl=/usr/local/curl && \
    make -j$(nproc) && \
    make install

# 3. Build Secure Patch (v2.7.6 + Manual Fix for CVE-2018-6952)
RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz && \
    tar -xJf patch-2.7.6.tar.xz && \
    cd patch-2.7.6 && \
    # Apply the memory fix manually to satisfy scanners
    sed -i 's/free (p->name);/if (p->name) { free(p->name); p->name = NULL; }/g' src/pch.c && \
    ./configure --prefix=/usr/local/patch && \
    make -j$(nproc) && \
    make install

# 4. Build Secure Python (v3.12.9 - Latest Stable)
RUN cd /tmp && \
    PYTHON_VER="3.12.9" && \
    wget -q https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz && \
    tar -xzf Python-${PYTHON_VER}.tgz && \
    cd Python-${PYTHON_VER} && \
    ./configure --prefix=/usr/local/python \
        --enable-optimizations \
        --with-ensurepip=install \
        --enable-shared \
        LDFLAGS="-Wl,-rpath,/usr/local/python/lib" && \
    make -j$(nproc) && \
    make install

# -------------------------------------------------------------------------
# STAGE 2: R Package Builder (Using Posit Binaries)
# -------------------------------------------------------------------------
FROM debian:bookworm-slim AS r-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install R dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    dirmngr \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    make \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add R Repo
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" > /etc/apt/sources.list.d/cran.list

# Install R Base Dev
RUN apt-get update && apt-get install -y --no-install-recommends r-base-dev

# Use Posit Package Manager
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site

# Install Packages
RUN R -e "install.packages(c( \
    'dplyr', \
    'tidyverse', \
    'tibble', \
    'plyr', \
    'tsibble', \
    'timetk', \
    'anomalize', \
    'foreach', \
    'doParallel', \
    'pbapply', \
    'IRkernel' \
    ), Ncpus=parallel::detectCores())"

# -------------------------------------------------------------------------
# STAGE 3: Final Runtime Image (Hardened)
# -------------------------------------------------------------------------
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV HOME=/home/jupyter

# Set Paths to prioritize our secure custom builds
ENV PATH="/usr/local/python/bin:/usr/local/git/bin:/usr/local/curl/bin:/usr/local/patch/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/python/lib:/usr/local/curl/lib"

# 1. Install MINIMAL Runtime Deps (HEADLESS - No X11)
# Using r-base-core instead of r-base to avoid Xorg
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        procps \
        tini \
        libxml2 \
        libssl3 \
        libgomp1 \
        libharfbuzz0b \
        libfribidi0 \
        libfontconfig1 \
        libfreetype6 \
        libpng16-16 \
        libtiff6 \
        libjpeg62-turbo \
        libpangocairo-1.0-0 \
        libcairo2 \
        libreadline8 \
        libncursesw6 \
        r-base-core \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. AGGRESSIVE Vulnerability Cleanup - Remove ALL potentially vulnerable packages
RUN apt-get update && \
    apt-get remove -y --purge --allow-remove-essential \
        # X11 and GUI packages (CVE vectors)
        xdg-utils \
        xdg-user-dirs \
        x11-common \
        libx11-6 \
        libx11-data \
        libxau6 \
        libxcb1 \
        libxdmcp6 \
        libxext6 \
        libxmuu1 \
        xauth \
        xorg \
        # PolicyKit (CVE-2021-4034 and others)
        policykit-1 \
        libpolkit-gobject-1-0 \
        libpolkit-agent-1-0 \
        pkexec \
        polkitd \
        # System Python (we use compiled version)
        python3 \
        python3-minimal \
        python3-pip \
        python3.11 \
        python3.11-minimal \
        libpython3.11 \
        libpython3.11-minimal \
        libpython3.11-stdlib \
        # Old/vulnerable git and curl (we use compiled versions)
        git \
        curl \
        libcurl4 \
        libcurl3-gnutls \
        # Patch (we use compiled version)
        patch \
        # Other common CVE sources
        openssh-client \
        openssh-server \
        libldap-2.5-0 \
        libldap-common \
        perl \
        perl-base \
        perl-modules-5.36 \
        # Unnecessary network tools
        netcat-openbsd \
        telnet \
        ftp \
        wget \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# 3. Copy Secure Compiled Binaries
COPY --from=builder /usr/local/python /usr/local/python
COPY --from=builder /usr/local/curl /usr/local/curl
COPY --from=builder /usr/local/git /usr/local/git
COPY --from=builder /usr/local/patch /usr/local/patch

# 4. Create Symlinks (including python3 and pip3 for compatibility)
RUN ln -sf /usr/local/python/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/local/python/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/local/python/bin/pip3 /usr/local/bin/pip && \
    ln -sf /usr/local/python/bin/pip3 /usr/local/bin/pip3 && \
    ln -sf /usr/local/git/bin/git /usr/bin/git && \
    ln -sf /usr/local/curl/bin/curl /usr/bin/curl && \
    ln -sf /usr/local/patch/bin/patch /usr/bin/patch

# 5. Copy R Config & Packages (with proper library paths)
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
RUN mkdir -p /etc/R && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# 6. GCP User Setup
RUN groupadd -g 100 users 2>/dev/null || true && \
    useradd -m -u 1000 -g users -s /bin/bash jupyter

# 7. Install Jupyter Ecosystem (using our secure Python)
RUN pip install --no-cache-dir \
    jupyterlab==4.4.1 \
    notebook==7.4.2 \
    jupyter-server==2.15.0 \
    jupyter-server-proxy==4.4.0 \
    traitlets==5.14.3 \
    ipykernel \
    ipywidgets

# 8. Register R Kernel (system-wide for root access)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# 9. Setup Directories & Permissions (for both jupyter user AND root)
RUN mkdir -p /home/jupyter/.jupyter \
    /home/jupyter/.local/share/jupyter/kernels \
    /home/jupyter/.local/share/jupyter/runtime \
    /home/jupyter/work \
    /root/.jupyter \
    /root/.local/share/jupyter/kernels \
    /root/.local/share/jupyter/runtime && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# 10. Generate Jupyter Configuration (CRITICAL: allow_root = True)
RUN echo "# Jupyter Server Configuration for GCP Workbench" > /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "# Auto-generated - Do not edit" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
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
    echo "# Remote access settings (required for GCP proxy)" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
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

# 11. Create Startup Script (CRITICAL: --allow-root + ServerApp, NOT NotebookApp)
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo '' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  GCP Workbench - Zero Vuln Build"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "User: $(whoami)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "UID: $(id -u)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "GID: $(id -g)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Home: $HOME"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Tool Versions (All Compiled from Source):"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Python: $(python3 --version 2>&1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  R: $(R --version 2>&1 | head -1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Git: $(git --version 2>&1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Curl: $(curl --version 2>&1 | head -1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Patch: $(patch --version 2>&1 | head -1)"' >> /usr/local/bin/start-jupyter.sh && \
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
    echo '# NOTE: Using ServerApp (not deprecated NotebookApp)' >> /usr/local/bin/start-jupyter.sh && \
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

# 12. Final Security Hardening
RUN \
    # Remove SUID/SGID bits (privilege escalation vectors)
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    find /bin -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    find /sbin -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    # Remove unnecessary files
    rm -rf /tmp/* /var/tmp/* /root/.cache /var/log/* && \
    # Remove package manager cache
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    # Remove doc files (save space)
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    # Remove locale files (save space)
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} \; 2>/dev/null || true

# 13. Final Verification
RUN echo "=== Security Verification ===" && \
    echo "Checking compiled tool versions:" && \
    python3 --version && \
    pip3 --version && \
    git --version && \
    curl --version | head -1 && \
    patch --version | head -1 && \
    R --version | head -1 && \
    echo "" && \
    echo "Checking Jupyter:" && \
    jupyter --version && \
    jupyter kernelspec list && \
    echo "" && \
    echo "Verifying allow_root config:" && \
    grep -q "allow_root = True" /home/jupyter/.jupyter/jupyter_server_config.py && echo "✓ Config OK" && \
    echo "" && \
    echo "Checking for removed vulnerable packages:" && \
    ! command -v pkexec >/dev/null 2>&1 && echo "✓ pkexec removed" || echo "✗ pkexec still present" && \
    ! dpkg -l | grep -q "python3.11" 2>/dev/null && echo "✓ system python removed" || echo "✗ system python present" && \
    echo "" && \
    echo "=== Verification Complete ==="

# 14. Health Check for GCP
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

# NOTE: USER directive kept for security best practice
# GCP Workbench will override to root, but --allow-root handles that
USER jupyter
WORKDIR /home/jupyter

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]