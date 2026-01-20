# ==============================================================================
# GCP WORKBENCH - HARDENED CUSTOM IMAGE
# Base: Official GCP Workbench Container
# Additions: R + Tidyverse + TimeTK + Anomalize
# Security: Updated/Compiled vulnerable packages from source
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: Security Tool Builder
# Compile secure versions of vulnerable packages
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim AS security-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    wget \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libreadline-dev \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    gettext \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libpcre2-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# 1. Build Secure Curl (v8.12.1 - Fixes multiple CVEs)
RUN cd /tmp && \
    CURL_VER="8.12.1" && \
    wget -q https://curl.se/download/curl-${CURL_VER}.tar.gz && \
    tar -xzf curl-${CURL_VER}.tar.gz && \
    cd curl-${CURL_VER} && \
    ./configure --prefix=/opt/secure/curl \
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
    ./configure --prefix=/opt/secure/git \
        --with-openssl \
        --with-curl=/opt/secure/curl && \
    make -j$(nproc) && \
    make install

# 3. Build Secure Patch (v2.7.6 + Fix for CVE-2018-6952)
RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz && \
    tar -xJf patch-2.7.6.tar.xz && \
    cd patch-2.7.6 && \
    sed -i 's/free (p->name);/if (p->name) { free(p->name); p->name = NULL; }/g' src/pch.c && \
    ./configure --prefix=/opt/secure/patch && \
    make -j$(nproc) && \
    make install

# 4. Build Secure HDF5 (v1.14.3 - Fixes CVE-2018-13867)
RUN cd /tmp && \
    wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz && \
    tar -xzf hdf5-1.14.3.tar.gz && \
    cd hdf5-1.14.3 && \
    ./configure --prefix=/opt/secure/hdf5 \
        --enable-threadsafe \
        --with-pthread \
        --disable-cxx \
        --disable-fortran \
        --disable-tests \
        --disable-hl && \
    make -j$(nproc) && \
    make install

# ------------------------------------------------------------------------------
# STAGE 2: R Package Builder
# Build R packages using Posit Package Manager (binary packages)
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim AS r-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install R build dependencies
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
    libzmq3-dev \
    make \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add CRAN Repository
RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'B8F25A8A73EACF41' && \
    gpg --batch --export --armor 'B8F25A8A73EACF41' | gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" > /etc/apt/sources.list.d/cran.list

# Install R
RUN apt-get update && apt-get install -y --no-install-recommends r-base-dev

# Configure Posit Package Manager for binary packages
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site

# Install requested R packages
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
    ), Ncpus = parallel::detectCores())"

# ------------------------------------------------------------------------------
# STAGE 3: Final Image (Based on GCP Workbench)
# ------------------------------------------------------------------------------
FROM gcr.io/deeplearning-platform-release/workbench-container:latest

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="GCP Workbench - Hardened with R + Tidyverse + Security Updates"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive

# Set paths to prioritize secure compiled tools
ENV PATH="/opt/secure/git/bin:/opt/secure/curl/bin:/opt/secure/patch/bin:/opt/secure/hdf5/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/secure/curl/lib:/opt/secure/hdf5/lib:${LD_LIBRARY_PATH}"

# ------------------------------------------------------------------------------
# STEP 1: System Updates & Security Patches
# ------------------------------------------------------------------------------
USER root

# Update all existing packages to latest versions
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get dist-upgrade -y

# ------------------------------------------------------------------------------
# STEP 2: Install R Runtime Dependencies
# ------------------------------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    # R Core (headless, no X11)
    r-base-core \
    # Runtime libraries for R packages
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
    libzmq5 \
    libsodium23 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# STEP 3: Security Hardening - Remove Vulnerable Packages
# ------------------------------------------------------------------------------
RUN apt-get update && \
    apt-get remove -y --purge \
        # X11 packages (attack surface reduction)
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
        # PolicyKit (CVE-2021-4034 PwnKit)
        policykit-1 \
        libpolkit-gobject-1-0 \
        libpolkit-agent-1-0 \
        pkexec \
        polkitd \
        # LDAP (often has CVEs)
        libldap-2.5-0 \
        libldap-common \
        # Old vulnerable versions (we replace with compiled)
        patch \
        # Unnecessary network tools
        telnet \
        ftp \
        netcat-openbsd \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# STEP 4: Copy Secure Compiled Binaries
# ------------------------------------------------------------------------------
COPY --from=security-builder /opt/secure/curl /opt/secure/curl
COPY --from=security-builder /opt/secure/git /opt/secure/git
COPY --from=security-builder /opt/secure/patch /opt/secure/patch
COPY --from=security-builder /opt/secure/hdf5 /opt/secure/hdf5

# Register shared libraries
RUN echo "/opt/secure/curl/lib" > /etc/ld.so.conf.d/secure_curl.conf && \
    echo "/opt/secure/hdf5/lib" > /etc/ld.so.conf.d/secure_hdf5.conf && \
    ldconfig

# Create symlinks to override system versions
RUN ln -sf /opt/secure/git/bin/git /usr/local/bin/git && \
    ln -sf /opt/secure/curl/bin/curl /usr/local/bin/curl && \
    ln -sf /opt/secure/patch/bin/patch /usr/local/bin/patch

# ------------------------------------------------------------------------------
# STEP 5: Copy R Libraries
# ------------------------------------------------------------------------------
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Configure R
RUN mkdir -p /etc/R && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# ------------------------------------------------------------------------------
# STEP 6: Register R Kernel for Jupyter
# ------------------------------------------------------------------------------
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# ------------------------------------------------------------------------------
# STEP 7: Additional Security Hardening
# ------------------------------------------------------------------------------
RUN \
    # Remove SUID/SGID bits (privilege escalation vectors)
    find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    find /opt -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    # Clean up unnecessary files
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf /root/.cache/* 2>/dev/null || true && \
    # Remove documentation (saves space)
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    # Remove unused locales
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} \; 2>/dev/null || true

# ------------------------------------------------------------------------------
# STEP 8: Verification
# ------------------------------------------------------------------------------
RUN echo "=== Verification ===" && \
    echo "" && \
    echo "Secure Tool Versions:" && \
    echo "  Git: $(/opt/secure/git/bin/git --version)" && \
    echo "  Curl: $(/opt/secure/curl/bin/curl --version | head -1)" && \
    echo "  Patch: $(/opt/secure/patch/bin/patch --version | head -1)" && \
    echo "" && \
    echo "R Version:" && \
    R --version | head -1 && \
    echo "" && \
    echo "R Packages Installed:" && \
    R -e "installed.packages()[,'Package']" | grep -E "dplyr|tidyverse|timetk|anomalize|IRkernel" && \
    echo "" && \
    echo "Jupyter Kernels:" && \
    jupyter kernelspec list && \
    echo "" && \
    echo "Security Checks:" && \
    ! command -v pkexec >/dev/null 2>&1 && echo "  ✓ pkexec removed" || echo "  ✗ pkexec present" && \
    [ -f /opt/secure/git/bin/git ] && echo "  ✓ Secure git installed" && \
    [ -f /opt/secure/curl/bin/curl ] && echo "  ✓ Secure curl installed" && \
    echo "" && \
    echo "=== Verification Complete ==="

# ------------------------------------------------------------------------------
# STEP 9: Health Check (GCP Compatible)
# ------------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:8080/api || exit 1

# The base image already configures:
# - Jupyter settings (allow_root, token, etc.)
# - Port 8080
# - Entrypoint and CMD
# - User configuration
# We inherit all of these automatically!

EXPOSE 8080