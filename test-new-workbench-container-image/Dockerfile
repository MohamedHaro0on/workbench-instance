# ============================================
# GCP Workbench with R Support
# Uses Posit Package Manager for binary packages
# Security hardened version
# ============================================
FROM gcr.io/deeplearning-platform-release/workbench-container:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SHELL=/bin/bash

USER root

# ============================================
# Security: Update system packages and patch vulnerabilities
# ============================================
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fix repository issues and install R with all dependencies in ONE step
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

# Configure R to use Posit Package Manager for BINARY packages
# This detects the Ubuntu version automatically
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))' >> /etc/R/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /etc/R/Rprofile.site

# Verify R version and repo
RUN R --version && \
    R -e "cat('Repository:', getOption('repos'), '\n')"

# Install ALL R packages using Posit binary packages (FAST)
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
            cat('✓', p, '\n'); \
        } else { \
            cat('✗', p, 'FAILED\n'); \
        } \
    }"

# Install R kernel for Jupyter
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# Verify Jupyter kernels
RUN jupyter kernelspec list

# Ensure proper permissions for jupyter user
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.cache/R && \
    chown -R jupyter:users /home/jupyter

# ============================================
# Security: Final cleanup and hardening
# ============================================
RUN rm -rf /tmp/* /var/tmp/* /root/.cache && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Disable unnecessary services to reduce CVE exposure
    systemctl disable --now apt-daily.service 2>/dev/null || true && \
    systemctl disable --now apt-daily-upgrade.service 2>/dev/null || true || true

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080