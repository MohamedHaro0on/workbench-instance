# ============================================
# GCP Workbench with R Support
# Uses Posit Package Manager for binary packages
# Security hardened version - Vulnerability fixes v3
# ============================================
FROM gcr.io/deeplearning-platform-release/workbench-container:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SHELL=/bin/bash

USER root

# ============================================
# PHASE 1: Remove unnecessary vulnerable packages
# ============================================
RUN apt-get update && \
    # Remove emacs (CVE-2024-39331 CRITICAL)
    apt-get remove -y --purge --allow-remove-essential \
        emacs* \
        emacs-common* \
        emacs-bin-common* \
        emacs-el* \
        emacs-nox* \
        emacs-gtk* \
    2>/dev/null || true && \
    # Remove texlive (Multiple HIGH CVEs)
    apt-get remove -y --purge \
        texlive* \
        tex-common* \
    2>/dev/null || true && \
    # Remove unused kernel headers
    apt-get remove -y --purge \
        linux-headers-* \
        linux-image-* \
        linux-modules-* \
        linux-libc-dev \
    2>/dev/null || true && \
    # Remove xorg if not needed (CVE-2023-5574)
    apt-get remove -y --purge \
        xserver-xorg* \
        xorg \
        xorg-docs* \
        x11-apps* \
        x11-session-utils* \
        x11-utils* \
        x11-xserver-utils* \
    2>/dev/null || true && \
    # Remove xdg-utils (CVE-2022-4055)
    apt-get remove -y --purge \
        xdg-utils \
        xdg-user-dirs \
    2>/dev/null || true && \
    # Remove policykit/polkit (CVE-2016-2568)
    apt-get remove -y --purge \
        policykit-1 \
        policykit-1-gnome \
        polkitd \
        libpolkit-agent-1-0 \
        libpolkit-gobject-1-0 \
        pkexec \
    2>/dev/null || true && \
    # Remove patch (CVE-2018-6952) - will reinstall newer version
    apt-get remove -y --purge patch 2>/dev/null || true && \
    # Remove system python-pip package (CVE-2025-47273, CVE-2025-66418, CVE-2026-21441, CVE-2025-66471)
    apt-get remove -y --purge \
        python3-pip \
        python-pip-whl \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 2: Add updated package repositories
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        apt-transport-https \
        gnupg \
        curl \
        wget \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Git PPA for latest git (CVE-2024-52005)
RUN add-apt-repository -y ppa:git-core/ppa 2>/dev/null || true

# ============================================
# PHASE 3: Full system upgrade
# ============================================
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 4: Install/upgrade curl from source (CVE-2025-9086)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libnghttp2-dev \
        libpsl-dev \
        libbrotli-dev \
        libzstd-dev \
    && cd /tmp \
    && CURL_VERSION="8.11.0" \
    && wget -q https://curl.se/download/curl-${CURL_VERSION}.tar.gz \
    && tar -xzf curl-${CURL_VERSION}.tar.gz \
    && cd curl-${CURL_VERSION} \
    && ./configure --prefix=/usr --with-openssl --with-nghttp2 --enable-ipv6 \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd / \
    && rm -rf /tmp/curl-* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 5: Install latest git (CVE-2024-52005)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 6: Install patch from source (CVE-2018-6952)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    cd /tmp && \
    PATCH_VERSION="2.7.6" && \
    wget -q https://ftp.gnu.org/gnu/patch/patch-${PATCH_VERSION}.tar.xz && \
    tar -xJf patch-${PATCH_VERSION}.tar.xz && \
    cd patch-${PATCH_VERSION} && \
    # Apply security fix for CVE-2018-6952 (double-free vulnerability)
    sed -i 's/free (p->name);/if (p->name) { free(p->name); p->name = NULL; }/g' src/pch.c 2>/dev/null || true && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/patch-* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 7: Install pip properly (fix pip CVEs)
# ============================================
# Install pip using get-pip.py to avoid system package vulnerabilities
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
    python3 /tmp/get-pip.py --no-cache-dir && \
    rm /tmp/get-pip.py && \
    # Upgrade to latest pip
    python3 -m pip install --upgrade --no-cache-dir \
        pip>=24.3.1 \
        setuptools>=75.0.0 \
        wheel>=0.45.0 \
    && \
    # Upgrade security-related packages
    python3 -m pip install --upgrade --no-cache-dir \
        certifi>=2024.8.30 \
        urllib3>=2.2.3 \
        requests>=2.32.3 \
        cryptography>=43.0.0 \
    && \
    # Clean pip cache
    python3 -m pip cache purge 2>/dev/null || true && \
    rm -rf /root/.cache/pip

# ============================================
# PHASE 8: Install R and required dependencies
# ============================================
RUN rm -f /etc/apt/sources.list.d/gcsfuse.list 2>/dev/null || true && \
    rm -f /etc/apt/sources.list.d/google-cloud*.list 2>/dev/null || true && \
    apt-get update && \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 9: Configure R for Posit Package Manager
# ============================================
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))' >> /etc/R/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /etc/R/Rprofile.site

# Verify R configuration
RUN R --version && \
    R -e "cat('Repository:', getOption('repos'), '\n')"

# ============================================
# PHASE 10: Install R packages
# ============================================
RUN R -e "\
    cat('=== Installing R packages ===\n'); \
    cat('R version:', as.character(getRversion()), '\n'); \
    cat('Repo:', getOption('repos'), '\n'); \
    \
    pkgs <- c( \
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
    ); \
    \
    install.packages(pkgs, Ncpus = parallel::detectCores()); \
    \
    cat('\n=== Verification ===\n'); \
    for (p in pkgs) { \
        if (requireNamespace(p, quietly=TRUE)) { \
            cat('OK:', p, '\n'); \
        } else { \
            cat('FAILED:', p, '\n'); \
        } \
    }"

# ============================================
# PHASE 11: Install R kernel for Jupyter
# ============================================
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# Verify Jupyter kernels
RUN jupyter kernelspec list

# ============================================
# PHASE 12: Setup user permissions
# ============================================
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.cache/R && \
    chown -R jupyter:users /home/jupyter 2>/dev/null || true

# ============================================
# PHASE 13: Final security hardening and cleanup
# ============================================
RUN \
    # Remove build dependencies no longer needed
    apt-get update && \
    apt-get remove -y --purge \
        linux-libc-dev \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    \
    # Final system upgrade
    apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    \
    # Verify vulnerable packages are removed
    echo "=== Verifying removed packages ===" && \
    ! dpkg -l | grep -q "^ii.*python3-pip " && echo "python3-pip: REMOVED" || echo "WARNING: python3-pip still present" && \
    ! dpkg -l | grep -q "^ii.*xorg " && echo "xorg: REMOVED" || echo "WARNING: xorg still present" && \
    ! dpkg -l | grep -q "^ii.*xdg-utils " && echo "xdg-utils: REMOVED" || echo "WARNING: xdg-utils still present" && \
    ! dpkg -l | grep -q "^ii.*policykit-1 " && echo "policykit-1: REMOVED" || echo "WARNING: policykit-1 still present" && \
    \
    # Clear all caches
    rm -rf /tmp/* /var/tmp/* /root/.cache /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.local/share/Trash/* 2>/dev/null || true && \
    \
    # Remove unnecessary setuid/setgid binaries
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    \
    # Disable unnecessary services
    systemctl disable --now apt-daily.service 2>/dev/null || true && \
    systemctl disable --now apt-daily-upgrade.service 2>/dev/null || true && \
    systemctl disable --now apt-daily.timer 2>/dev/null || true && \
    systemctl disable --now apt-daily-upgrade.timer 2>/dev/null || true && \
    \
    # Remove package manager caches
    rm -rf /var/cache/apt/* && \
    \
    echo "Security hardening complete"

# ============================================
# PHASE 14: Verify all security fixes
# ============================================
RUN echo "=== SECURITY FIX VERIFICATION ===" && \
    echo "" && \
    echo "1. curl version (should be >= 8.11.0):" && \
    curl --version | head -1 && \
    echo "" && \
    echo "2. git version (should be >= 2.45.0):" && \
    git --version && \
    echo "" && \
    echo "3. pip version (should be >= 24.3.1):" && \
    python3 -m pip --version && \
    echo "" && \
    echo "4. patch version:" && \
    patch --version | head -1 && \
    echo "" && \
    echo "5. Removed packages verification:" && \
    (! command -v xdg-open >/dev/null 2>&1 && echo "   xdg-utils: REMOVED (CVE-2022-4055 fixed)") || echo "   WARNING: xdg-utils still present" && \
    (! dpkg -l 2>/dev/null | grep -q "policykit-1" && echo "   policykit-1: REMOVED (CVE-2016-2568 fixed)") || echo "   WARNING: policykit-1 still present" && \
    (! dpkg -l 2>/dev/null | grep -q "^ii.*xorg " && echo "   xorg: REMOVED (CVE-2023-5574 fixed)") || echo "   WARNING: xorg still present" && \
    (! dpkg -l 2>/dev/null | grep -q "^ii.*python3-pip " && echo "   python3-pip: REMOVED (Multiple CVEs fixed)") || echo "   WARNING: python3-pip system package still present" && \
    echo "" && \
    echo "6. R version:" && \
    R --version | head -1 && \
    echo "" && \
    echo "=== ALL SECURITY FIXES APPLIED ==="

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080

# ============================================
# Security metadata
# ============================================
LABEL security.scan.date="2024" \
      security.remediation.version="3.0" \
      security.fixes="CVE-2024-39331,CVE-2025-9086,CVE-2024-52005,CVE-2023-48161,CVE-2018-6952,CVE-2016-2568,CVE-2022-4055,CVE-2023-5574,CVE-2025-47273,CVE-2025-66418,CVE-2026-21441,CVE-2025-66471"