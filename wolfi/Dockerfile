# ============================================
# GCP Workbench - Maximum Security Version
# Based on Chainguard Wolfi (near-zero CVEs)
# ============================================

# ============================================
# Stage 1: Python Builder
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest AS python-builder

USER root

RUN apk update && apk add --no-cache \
    python-3.12 \
    python-3.12-dev \
    py3.12-pip \
    py3.12-setuptools \
    py3.12-wheel \
    build-base

RUN python3.12 -m venv /opt/jupyter-venv

RUN /opt/jupyter-venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/jupyter-venv/bin/pip install --no-cache-dir \
        jupyterlab==4.4.1 \
        notebook==7.4.2 \
        jupyter-server==2.15.0 \
        jupyter-server-proxy==4.4.0 \
        traitlets==5.14.3 \
        ipykernel \
        ipywidgets

# ============================================
# Stage 2: R Builder
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest AS r-builder

USER root

# Install R and build dependencies
RUN apk update && apk add --no-cache \
    R \
    R-dev \
    build-base \
    gcc \
    g++ \
    gfortran \
    make \
    curl \
    wget \
    bash \
    openssl-dev \
    curl-dev \
    libxml2-dev \
    fontconfig-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    tiff-dev \
    harfbuzz-dev \
    fribidi-dev \
    cairo-dev \
    pango-dev \
    linux-headers \
    pkgconf \
    git \
    icu-dev \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    readline

# Setup R library directory
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 777 /usr/local/lib/R/site-library && \
    mkdir -p /etc/R

# Copy the R installation script
COPY install_packages.R /tmp/install_packages.R
COPY packages.txt /tmp/packages.txt

# Run R package installation script (won't fail build on package errors)
RUN Rscript /tmp/install_packages.R || echo "Some R packages may have failed, continuing..."

# ============================================
# Stage 3: Final Runtime Image
# ============================================
FROM cgr.dev/chainguard/wolfi-base:latest

USER root

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV VIRTUAL_ENV=/opt/jupyter-venv
ENV PATH="/opt/jupyter-venv/bin:${PATH}"
ENV HOME=/home/jupyter

# Install minimal runtime packages
RUN apk update && apk add --no-cache \
    R \
    python-3.12 \
    bash \
    tini \
    curl \
    libxml2 \
    fontconfig \
    freetype \
    libpng \
    libjpeg-turbo \
    tiff \
    harfbuzz \
    fribidi \
    cairo \
    pango \
    glib \
    libgit2 \
    libssh2 \
    icu \
    zlib \
    bzip2 \
    xz \
    pcre2 \
    readline \
    ncurses \
    ncurses-terminfo-base \
    libgfortran \
    libgomp \
    && rm -rf /var/cache/apk/*

# Create jupyter user
RUN (getent group users >/dev/null 2>&1 || addgroup -g 100 users) && \
    adduser -D -u 1000 -G users -h /home/jupyter -s /bin/bash jupyter

# Copy from builders
COPY --from=python-builder /opt/jupyter-venv /opt/jupyter-venv
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Configure R
RUN mkdir -p /usr/local/lib/R/site-library /etc/R && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# Install R kernel for Jupyter (if IRkernel available)
RUN Rscript -e 'if(requireNamespace("IRkernel",quietly=TRUE)){IRkernel::installspec(user=FALSE,name="ir",displayname="R")}' || true

# Setup directories
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/work && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# Copy configuration files
COPY --chown=jupyter:users jupyter_server_config.py /home/jupyter/.jupyter/
COPY --chown=root:root start-jupyter.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-jupyter.sh

# Security hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache 2>/dev/null || true

# Verification
RUN echo "=== Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    /opt/jupyter-venv/bin/jupyter --version && \
    /opt/jupyter-venv/bin/jupyter kernelspec list && \
    echo "=== Complete ==="

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]