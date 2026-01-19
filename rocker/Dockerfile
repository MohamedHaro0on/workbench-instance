# ============================================
# GCP Workbench with R Support (Secured + Fixed)
# Based on rocker/r-ver
# ============================================
FROM rocker/r-ver:4.4.2

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SHELL=/bin/bash
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ============================================
# 1. Install System Dependencies & Security Upgrades
# ============================================
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-dev \
    python3-venv \
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
    tini \
    procps \
    bash \
    curl \
    wget \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. Install Pip via Bootstrap (Fixed for PEP 668)
# ============================================
# We use --break-system-packages because this is a container, 
# so we want global python packages without using a virtualenv.
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py --break-system-packages && \
    rm get-pip.py && \
    pip3 install --no-cache-dir --break-system-packages \
        jupyterlab==4.4.1 \
        notebook==7.4.2 \
        jupyter-server==2.15.0 \
        jupyter-server-proxy==4.4.0 \
        traitlets==5.14.3 \
    && rm -rf /root/.cache/pip

# ============================================
# 3. Configure R for Posit Package Manager
# ============================================
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /usr/local/lib/R/etc/Rprofile.site

# ============================================
# 4. Install R packages
# ============================================
COPY packages.txt /tmp/packages.txt

RUN R -e "\
    cat('=== Installing R packages ===\n'); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, Ncpus = parallel::detectCores()); \
    install.packages('IRkernel', Ncpus = parallel::detectCores()); \
    cat('\n=== Verification ===\n'); \
    for (p in c(packages, 'IRkernel')) { \
        if (requireNamespace(p, quietly=TRUE)) { \
            cat('[OK]', p, '\n'); \
        } else { \
            cat('[FAIL]', p, '\n'); \
        } \
    }"

# ============================================
# 5. Create jupyter user (GCP Workbench requirement)
# ============================================
RUN groupadd -g 100 users 2>/dev/null || true && \
    useradd -m -u 1000 -g users -s /bin/bash jupyter && \
    mkdir -p /home/jupyter/.jupyter && \
    mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.cache && \
    mkdir -p /home/jupyter/work

# ============================================
# 6. Install R kernel for Jupyter
# ============================================
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# ============================================
# 7. Create Jupyter configuration
# ============================================
COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py

# ============================================
# 8. Create startup script
# ============================================
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# ============================================
# 9. Set permissions
# ============================================
RUN chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# ============================================
# 10. Security cleanup
# ============================================
RUN rm -rf /tmp/* /var/tmp/* /root/.cache && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose port 8080 (GCP Workbench requirement)
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start Jupyter
CMD ["/usr/local/bin/start-jupyter.sh"]