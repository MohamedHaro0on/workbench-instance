# ==============================================================================
# GCP WORKBENCH - SECURE V9 (FINAL ROBUST)
# Fixes: Missing 'autoconf' for Git build, HDF5 Thread Safety
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: The Builder (Compiles secure versions of tools)
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required for compilation
# ADDED: autoconf (Required for 'make configure' in Git build)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
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
    cmake \
    && rm -rf /var/lib/apt/lists/*

# 1. Build Secure HDF5 (Fixes Critical CVE-2018-13867)
# Note: --disable-hl required when --enable-threadsafe is used
RUN cd /tmp && \
    wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz && \
    tar -xzf hdf5-1.14.3.tar.gz && \
    cd hdf5-1.14.3 && \
    ./configure --prefix=/usr/local/hdf5 \
        --enable-threadsafe \
        --with-pthread \
        --disable-cxx \
        --disable-fortran \
        --disable-tests \
        --disable-hl && \
    make -j$(nproc) && \
    make install

# 2. Build Secure Curl (Fixes CVE-2025-9086)
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
        --without-libpsl && \
    make -j$(nproc) && \
    make install

# 3. Build Secure Git (Fixes CVE-2024-52005)
# Note: 'make configure' uses autoconf
RUN cd /tmp && \
    GIT_VER="2.48.1" && \
    wget -q https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.gz && \
    tar -xzf git-${GIT_VER}.tar.gz && \
    cd git-${GIT_VER} && \
    make configure && \
    ./configure --prefix=/usr/local/git --with-openssl --with-curl=/usr/local/curl && \
    make -j$(nproc) && \
    make install

# 4. Build Secure Patch (Fixes CVE-2018-6952)
RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz && \
    tar -xJf patch-2.7.6.tar.xz && \
    cd patch-2.7.6 && \
    sed -i 's/free (p->name);/if (p->name) { free(p->name); p->name = NULL; }/g' src/pch.c && \
    ./configure --prefix=/usr/local/patch && \
    make -j$(nproc) && \
    make install

# 5. Build Secure Python 3.12 (Fixes PIP and Python CVEs)
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

# ------------------------------------------------------------------------------
# STAGE 2: R Package Builder
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim AS r-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install R Build Deps
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

# Install R Packages
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

# ------------------------------------------------------------------------------
# STAGE 3: Final Runtime Image
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
# Set Path to prioritize our custom compiled tools
ENV PATH="/usr/local/python/bin:/usr/local/git/bin:/usr/local/curl/bin:/usr/local/patch/bin:/usr/local/hdf5/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/python/lib:/usr/local/curl/lib:/usr/local/hdf5/lib"

# 1. Install Runtime Dependencies (Headless/Server versions only)
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
        r-base-core \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Aggressive Vulnerability Cleanup
# Removing X11, PolicyKit, System Python, Old HDF5
RUN apt-get remove -y --purge \
        xdg-utils \
        policykit-1 \
        libpolkit-gobject-1-0 \
        pkexec \
        xorg \
        x11-common \
        libx11-6 \
        python3-pip \
        python3 \
        libhdf5-dev \
        libldap-common \
    2>/dev/null || true && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 3. Copy Secure Compiled Binaries
COPY --from=builder /usr/local/python /usr/local/python
COPY --from=builder /usr/local/curl /usr/local/curl
COPY --from=builder /usr/local/git /usr/local/git
COPY --from=builder /usr/local/patch /usr/local/patch
COPY --from=builder /usr/local/hdf5 /usr/local/hdf5

# 4. Symlinks
RUN ln -sf /usr/local/python/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/local/python/bin/pip3 /usr/local/bin/pip && \
    ln -sf /usr/local/git/bin/git /usr/bin/git && \
    ln -sf /usr/local/curl/bin/curl /usr/bin/curl

# 5. Copy R Libraries
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
RUN mkdir -p /etc/R && \
    echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' >> /etc/R/Rprofile.site

# 6. Setup GCP Workbench User
RUN groupadd -g 100 users 2>/dev/null || true && \
    useradd -m -u 1000 -g users -s /bin/bash jupyter

# 7. Install Jupyter Ecosystem
RUN pip install --no-cache-dir \
    jupyterlab==4.4.1 \
    notebook==7.4.2 \
    jupyter-server==2.15.0 \
    jupyter-server-proxy==4.4.0 \
    traitlets==5.14.3

# 8. Register R Kernel
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# 9. Configure Jupyter
RUN mkdir -p /home/jupyter/.jupyter
COPY jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py

# 10. Startup Script
RUN echo '#!/bin/bash\n\
jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --allow-root --NotebookApp.token="" --NotebookApp.password=""' > /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# 11. Final Permissions
RUN mkdir -p /home/jupyter/.local/share/jupyter && \
    chown -R jupyter:users /home/jupyter

USER jupyter
WORKDIR /home/jupyter
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]