# ============================================
# GCP Workbench with R Support
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
    apt-get remove -y --purge --allow-remove-essential \
        emacs* \
        emacs-common* \
        texlive* \
        tex-common* \
        xdg-utils \
        xdg-user-dirs \
        policykit-1 \
        polkitd \
        libpolkit-agent-1-0 \
        libpolkit-gobject-1-0 \
    2>/dev/null || true && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 2: Full system upgrade
# ============================================
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 3: Upgrade vulnerable packages
# ============================================
RUN apt-get update && \
    apt-get install -y --only-upgrade \
        curl \
        libcurl4 \
        libcurl4-openssl-dev \
        git \
        libgif7 \
        patch \
    2>/dev/null || true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# PHASE 4: Upgrade pip (fix pip CVEs)
# ============================================
RUN pip3 install --no-cache-dir --upgrade \
        pip>=24.3.1 \
        setuptools>=75.0.0 \
        wheel>=0.45.0 \
        certifi>=2024.8.30 \
        urllib3>=2.2.3 \
        requests>=2.32.3 \
    2>/dev/null || true && \
    rm -rf /root/.cache/pip

# ============================================
# PHASE 5: Fix repository issues and install R
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
# PHASE 6: Configure R for Posit Package Manager
# ============================================
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))' >> /etc/R/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /etc/R/Rprofile.site

# Verify R configuration
RUN R --version && \
    R -e "cat('Repository:', getOption('repos'), '\n')"

# ============================================
# PHASE 7: Install R packages
# ============================================
COPY packages.txt /tmp/packages.txt

RUN R -e "\
    cat('=== Installing R packages ===\n'); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, Ncpus = parallel::detectCores()); \
    cat('\n=== Verification ===\n'); \
    for (p in packages) { \
        if (requireNamespace(p, quietly=TRUE)) { \
            cat('[OK]', p, '\n'); \
        } else { \
            cat('[FAIL]', p, '\n'); \
        } \
    }"

# ============================================
# PHASE 8: Install IRkernel for Jupyter
# ============================================
RUN R -e "install.packages('IRkernel', Ncpus = parallel::detectCores())" && \
    R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# Verify Jupyter kernels
RUN jupyter kernelspec list

# ============================================
# PHASE 9: Setup Jupyter configuration
# ============================================
RUN mkdir -p /home/jupyter/.jupyter

COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# ============================================
# PHASE 10: Set permissions
# ============================================
RUN mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.cache/R && \
    mkdir -p /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter

# ============================================
# PHASE 11: Final security hardening
# ============================================
RUN rm -rf /tmp/* /var/tmp/* /root/.cache && \
    rm -rf /home/jupyter/.cache/yarn 2>/dev/null || true && \
    rm -rf /home/jupyter/.npm 2>/dev/null || true && \
    rm -rf /opt/micromamba/pkgs/* 2>/dev/null || true && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc/* /usr/share/man/*

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use startup script
ENTRYPOINT ["/usr/local/bin/start-jupyter.sh"]