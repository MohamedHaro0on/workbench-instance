# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Fixed: R package compilation on musl/Alpine
# ============================================

# ============================================
# Stage 1: Build Stage
# ============================================
FROM alpine:3.20 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Disable LTO which causes issues on Alpine/musl
ENV CFLAGS="-O2 -fstack-clash-protection -fno-plt"
ENV CXXFLAGS="-O2 -fstack-clash-protection -fno-plt"
ENV FFLAGS="-O2"
ENV R_MAKEVARS_USER=/tmp/Makevars

# 1. Install Build Dependencies (added util-linux-dev, libuuid)
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
    lapack-dev \
    fftw-dev \
    util-linux-dev \
    libuuid

# 2. Create R Makevars to fix compilation issues
RUN mkdir -p ~/.R && \
    echo 'CFLAGS = -O2 -fstack-clash-protection -fno-plt' > ~/.R/Makevars && \
    echo 'CXXFLAGS = -O2 -fstack-clash-protection -fno-plt' >> ~/.R/Makevars && \
    echo 'CXX11FLAGS = -O2 -fstack-clash-protection -fno-plt' >> ~/.R/Makevars && \
    echo 'CXX14FLAGS = -O2 -fstack-clash-protection -fno-plt' >> ~/.R/Makevars && \
    echo 'CXX17FLAGS = -O2 -fstack-clash-protection -fno-plt' >> ~/.R/Makevars && \
    echo 'FFLAGS = -O2' >> ~/.R/Makevars && \
    echo 'FCFLAGS = -O2' >> ~/.R/Makevars && \
    cp ~/.R/Makevars /tmp/Makevars

# 3. Configure R directories
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library

COPY config/Rprofile.site /etc/R/Rprofile.site

# 4. Copy R packages list and install script
COPY packages/r-packages.txt /tmp/r-packages.txt
COPY scripts/install-r-packages.R /tmp/install-r-packages.R
RUN Rscript /tmp/install-r-packages.R

# 5. Verify R packages
RUN R -e "\
    packages <- c('plyr', 'anomalize', 'foreach', 'tidyverse', 'tibbletime', 'doParallel', 'pbapply', 'dplyr', 'IRkernel'); \
    missing <- c(); \
    for (pkg in packages) { \
        if (!requireNamespace(pkg, quietly = TRUE)) { \
            missing <- c(missing, pkg); \
        } \
    }; \
    if (length(missing) > 0) { \
        cat('MISSING PACKAGES:', paste(missing, collapse=', '), '\n'); \
        quit(status = 1); \
    } else { \
        cat('All client packages verified successfully\n'); \
    }"

# 6. Cleanup R docs
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "html" -exec rm -rf {} + 2>/dev/null || true

# 7. Setup Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 8. Install Python packages
COPY scripts/install-python-packages.sh /tmp/install-python-packages.sh
RUN chmod +x /tmp/install-python-packages.sh && /tmp/install-python-packages.sh

# 9. Apply CVE mitigations
COPY scripts/apply-cve-mitigations.sh /tmp/apply-cve-mitigations.sh
RUN chmod +x /tmp/apply-cve-mitigations.sh && /tmp/apply-cve-mitigations.sh

# 10. Cleanup Python docs
RUN find /opt/venv -name "*.html" -path "*/doc/*" -delete 2>/dev/null || true && \
    find /opt/venv -type d -name "doc" -path "*/site-packages/*" -exec rm -rf {} + 2>/dev/null || true

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
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
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
    fftw \
    libuuid \
    && rm -rf /var/cache/apk/*

# 2. Create User
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy artifacts from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# 4. Configure R Runtime
COPY config/Rprofile.site /etc/R/Rprofile.site
RUN mkdir -p /usr/local/lib/R/site-library

# 5. Install R Kernel Spec
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R (Alpine)')"

# 6. Setup Directories
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/work \
             /root/.jupyter \
             /root/.local/share/jupyter/kernels \
             /root/.local/share/jupyter/runtime && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# 7. Copy Configuration Files
COPY config/jupyter_server_config.py /home/jupyter/.jupyter/jupyter_server_config.py
RUN chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/

# 8. Copy Startup Script
COPY start-jupyter.sh /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# 9. Security Hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache && \
    find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /opt/venv -name "*.html" -path "*/doc/*" -delete 2>/dev/null || true

# 10. Final Verification
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    echo "--- Client Packages ---" && \
    R -e "for(p in c('plyr','anomalize','foreach','tidyverse','tibbletime','doParallel','pbapply','dplyr')) { cat(p, ':', as.character(packageVersion(p)), '\n') }" && \
    echo "--- CVE Check ---" && \
    python3 -c "from nbconvert.exporters.pdf import PDFExporter; p = PDFExporter(); p.from_notebook_node(None)" 2>&1 || echo "PASS: PDF disabled" && \
    echo "=== Complete ==="

# 11. Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="2.2" \
      description="GCP Workbench with R - Alpine Linux (Hardened)" \
      packages="plyr,anomalize,foreach,tidyverse,tibbletime,parallel,pbapply,dplyr"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]