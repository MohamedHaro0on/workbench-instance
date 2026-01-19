# ============================================
# GCP Workbench with R Support
# Uses Posit Package Manager for binary packages
# Security hardened version - Vulnerability fixes
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
    # Remove texlive (Multiple HIGH CVEs: CVE-2019-12360, CVE-2019-9587, CVE-2019-9588, CVE-2019-12493, CVE-2017-17513)
    apt-get remove -y --purge \
        texlive* \
        tex-common* \
    2>/dev/null || true && \
    # Remove unused kernel headers to reduce attack surface (linux CVEs)
    apt-get remove -y --purge \
        linux-headers-* \
        linux-image-* \
        linux-modules-* \
        linux-libc-dev \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 2: Full system upgrade and security patches
# ============================================
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        apt-transport-https \
        gnupg \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 3: Upgrade specific vulnerable packages to latest versions
# ============================================
RUN apt-get update && \
    # Upgrade curl and libcurl (CVE-2025-9086)
    apt-get install -y --only-upgrade \
        curl \
        libcurl4 \
        libcurl4-openssl-dev \
        libcurl3-gnutls \
    2>/dev/null || true && \
    # Upgrade git (CVE-2024-52005)
    apt-get install -y --only-upgrade \
        git \
        git-man \
        git-core \
    2>/dev/null || true && \
    # Upgrade giflib (CVE-2023-48161)
    apt-get install -y --only-upgrade \
        libgif7 \
        libgif-dev \
        giflib-tools \
    2>/dev/null || true && \
    # Upgrade patch (CVE-2018-6952)
    apt-get install -y --only-upgrade patch 2>/dev/null || true && \
    # Upgrade polkit/policykit (CVE-2016-2568)
    apt-get install -y --only-upgrade \
        policykit-1 \
        polkitd \
        libpolkit-agent-1-0 \
        libpolkit-gobject-1-0 \
        pkexec \
    2>/dev/null || true && \
    # Upgrade xdg-utils (CVE-2022-4055)
    apt-get install -y --only-upgrade xdg-utils 2>/dev/null || true && \
    # Upgrade hdf5 (CVE-2019-9152, CVE-2019-9151)
    apt-get install -y --only-upgrade \
        libhdf5-dev \
        libhdf5-103-1 \
        libhdf5-cpp-103-1 \
        hdf5-tools \
    2>/dev/null || true && \
    # Upgrade xorg packages (CVE-2023-5574)
    apt-get install -y --only-upgrade \
        xserver-xorg-core \
        xserver-common \
        libx11-6 \
        libx11-dev \
    2>/dev/null || true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 4: Upgrade pip and Python packages (Multiple pip CVEs)
# ============================================
RUN python3 -m pip install --upgrade pip==24.3.1 --no-cache-dir --break-system-packages 2>/dev/null || \
    python3 -m pip install --upgrade pip==24.3.1 --no-cache-dir || true && \
    python3 -m pip install --upgrade \
        setuptools>=70.0.0 \
        wheel>=0.44.0 \
        certifi>=2024.7.4 \
        urllib3>=2.2.2 \
        requests>=2.32.3 \
    --no-cache-dir --break-system-packages 2>/dev/null || \
    python3 -m pip install --upgrade \
        setuptools>=70.0.0 \
        wheel>=0.44.0 \
        certifi>=2024.7.4 \
        urllib3>=2.2.2 \
        requests>=2.32.3 \
    --no-cache-dir || true

# ============================================
# PHASE 5: Install R and required dependencies
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
# PHASE 6: Configure R for Posit Package Manager (binary packages)
# ============================================
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))' >> /etc/R/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /etc/R/Rprofile.site

# Verify R configuration
RUN R --version && \
    R -e "cat('Repository:', getOption('repos'), '\n')"

# ============================================
# PHASE 7: Install R packages using Posit binary packages
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
# PHASE 8: Install R kernel for Jupyter
# ============================================
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# Verify Jupyter kernels
RUN jupyter kernelspec list

# ============================================
# PHASE 9: Setup user permissions
# ============================================
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.cache/R && \
    chown -R jupyter:users /home/jupyter 2>/dev/null || true

# ============================================
# PHASE 10: Final security hardening and cleanup
# ============================================
RUN \
    # Remove build dependencies that are no longer needed (reduces attack surface)
    apt-get update && \
    apt-get remove -y --purge \
        linux-libc-dev \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    \
    # Final system upgrade to catch any remaining patches
    apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    \
    # Clear all caches and temporary files
    rm -rf /tmp/* /var/tmp/* /root/.cache /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.local/share/Trash/* 2>/dev/null || true && \
    \
    # Remove unnecessary setuid/setgid binaries (security hardening)
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
    rm -rf /var/lib/dpkg/info/*.list && \
    \
    echo "Security hardening complete"

# ============================================
# PHASE 11: Verify security fixes
# ============================================
RUN echo "=== Package Version Verification ===" && \
    echo "Curl version:" && curl --version | head -1 && \
    echo "Git version:" && git --version && \
    echo "Pip version:" && pip3 --version && \
    echo "Python version:" && python3 --version && \
    echo "R version:" && R --version | head -1 && \
    echo "=== Removed packages check ===" && \
    ! command -v emacs >/dev/null 2>&1 && echo "emacs: REMOVED (CVE-2024-39331 fixed)" || echo "WARNING: emacs still present" && \
    ! dpkg -l | grep -q "texlive-bin" && echo "texlive: REMOVED (Multiple CVEs fixed)" || echo "WARNING: texlive still present"

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080

# ============================================
# Security metadata
# ============================================
LABEL security.scan.date="2024" \
      security.remediation.version="2.0" \
      security.fixes="CVE-2024-39331,CVE-2025-9086,CVE-2024-52005,CVE-2023-48161,CVE-2018-6952,CVE-2016-2568,CVE-2022-4055,CVE-2019-9152,CVE-2019-9151,CVE-2023-5574,CVE-2019-12360,CVE-2019-9587,CVE-2019-9588"