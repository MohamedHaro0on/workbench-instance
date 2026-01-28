# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# Simplified: All R packages installed inline
# ============================================

FROM alpine:3.20 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV R_LIBS_USER=/usr/local/lib/R/site-library

# 1. Install ALL Build Dependencies
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

# 2. Setup R Library and Makevars (disable LTO)
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 777 /usr/local/lib/R/site-library && \
    mkdir -p ~/.R && \
    echo 'CFLAGS = -O2 -fPIC' > ~/.R/Makevars && \
    echo 'CXXFLAGS = -O2 -fPIC' >> ~/.R/Makevars && \
    echo 'CXX11FLAGS = -O2 -fPIC' >> ~/.R/Makevars && \
    echo 'CXX14FLAGS = -O2 -fPIC' >> ~/.R/Makevars && \
    echo 'CXX17FLAGS = -O2 -fPIC' >> ~/.R/Makevars && \
    echo 'FFLAGS = -O2' >> ~/.R/Makevars && \
    echo 'FCFLAGS = -O2' >> ~/.R/Makevars

# 3. Configure R
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /usr/lib/R/etc/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /usr/lib/R/etc/Rprofile.site && \
    echo 'options(Ncpus = parallel::detectCores())' >> /usr/lib/R/etc/Rprofile.site

# 4. Install R Core Packages (Layer 1)
RUN R -e "install.packages(c('rlang', 'cli', 'glue', 'vctrs', 'lifecycle', 'pillar', 'Rcpp', 'R6', 'magrittr'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 5. Install Data Packages (Layer 2)
RUN R -e "install.packages(c('tibble', 'dplyr', 'tidyr', 'purrr', 'readr', 'stringr', 'forcats'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 6. Install plyr, data.table (Layer 3)
RUN R -e "install.packages(c('plyr', 'data.table'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 7. Install ggplot2 (Layer 4)
RUN R -e "install.packages('ggplot2', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 8. Install Utilities (Layer 5)
RUN R -e "install.packages(c('jsonlite', 'lubridate', 'hms', 'withr', 'crayon'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 9. Install Parallel Packages (Layer 6)
RUN R -e "install.packages(c('foreach', 'iterators', 'doParallel', 'pbapply'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 10. Install Time Series Base (Layer 7)
RUN R -e "install.packages(c('zoo', 'xts', 'tseries', 'TTR', 'quantmod'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 11. Install forecast (Layer 8)
RUN R -e "install.packages('forecast', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 12. Install timetk deps and timetk (Layer 9)
RUN R -e "install.packages(c('timeDate', 'timetk'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 13. Install sweep (Layer 10 - try CRAN first, then archive)
RUN R -e "tryCatch(install.packages('sweep', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores()), error=function(e) install.packages('https://cran.r-project.org/src/contrib/Archive/sweep/sweep_0.2.5.tar.gz', repos=NULL, type='source', lib='/usr/local/lib/R/site-library'))"

# 14. Install tibbletime from CRAN Archive (Layer 11)
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/tibbletime/tibbletime_0.1.8.tar.gz', repos=NULL, type='source', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 15. Install tidyverse (Layer 12)
RUN R -e "install.packages('tidyverse', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 16. Install anomalize deps and anomalize (Layer 13)
RUN R -e "install.packages(c('assertthat', 'ggfortify', 'anomalize'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 17. Install IRkernel dependencies (Layer 14)
RUN R -e "install.packages(c('repr', 'IRdisplay', 'evaluate', 'digest', 'uuid'), lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 18. Install pbdZMQ with configure args (Layer 15)
RUN R -e "install.packages('pbdZMQ', lib='/usr/local/lib/R/site-library', configure.args='--with-zmq-include=/usr/include --with-zmq-lib=/usr/lib', Ncpus=parallel::detectCores())"

# 19. Install IRkernel (Layer 16)
RUN R -e "install.packages('IRkernel', lib='/usr/local/lib/R/site-library', Ncpus=parallel::detectCores())"

# 20. Verify ALL packages installed
RUN R -e "\
    .libPaths('/usr/local/lib/R/site-library'); \
    pkgs <- c('plyr','anomalize','foreach','tidyverse','tibbletime','doParallel','pbapply','dplyr','IRkernel'); \
    for(p in pkgs) { \
        if(require(p, character.only=TRUE, quietly=TRUE)) { \
            cat('OK:', p, as.character(packageVersion(p)), '\n'); \
        } else { \
            cat('FAIL:', p, '\n'); \
            quit(status=1); \
        } \
    }"

# 21. Cleanup R docs
RUN find /usr/local/lib/R/site-library -name "*.html" -delete 2>/dev/null || true && \
    find /usr/local/lib/R/site-library -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true

# 22. Setup Python venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 23. Install Python/Jupyter
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
        jupyterlab \
        notebook \
        jupyter-server \
        jupyter-server-proxy \
        traitlets \
        ipykernel \
        ipywidgets \
        nbconvert

# 24. Apply CVE-2025-53000 mitigation
RUN NBCONVERT_PATH=$(python3 -c "import nbconvert; import os; print(os.path.dirname(nbconvert.__file__))") && \
    echo 'from nbconvert.exporters.html import HTMLExporter' > "${NBCONVERT_PATH}/exporters/pdf.py" && \
    echo 'class PDFExporter(HTMLExporter):' >> "${NBCONVERT_PATH}/exporters/pdf.py" && \
    echo '    def from_notebook_node(self, nb, **kw): raise RuntimeError("PDF disabled for CVE-2025-53000")' >> "${NBCONVERT_PATH}/exporters/pdf.py" && \
    NBCONVERT_VERSION=$(python3 -c "import nbconvert; print(nbconvert.__version__)") && \
    SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])") && \
    rm -rf "${SITE_PACKAGES}/nbconvert-${NBCONVERT_VERSION}.dist-info" || true

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.20

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV R_LIBS_USER=/usr/local/lib/R/site-library
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/home/jupyter

# 1. Runtime Dependencies
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    bash tini ca-certificates R python3 curl libcurl libxml2 \
    fontconfig freetype libpng jpeg tiff harfbuzz fribidi \
    zeromq cairo pango glib libgit2 libssh2 icu-libs zlib \
    bzip2 xz-libs pcre2 readline libsodium openblas lapack \
    libgomp libgfortran ncurses ncurses-terminfo-base fftw libuuid \
    && rm -rf /var/cache/apk/*

# 2. Create User
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /usr/lib/R/etc/Rprofile.site /usr/lib/R/etc/Rprofile.site

# 4. Setup R library
RUN mkdir -p /usr/local/lib/R/site-library && chmod 755 /usr/local/lib/R/site-library

# 5. Install R Kernel
RUN R -e "IRkernel::installspec(user=FALSE, name='ir', displayname='R (Alpine)')"

# 6. Setup directories
RUN mkdir -p /home/jupyter/.jupyter \
             /home/jupyter/.local/share/jupyter/kernels \
             /home/jupyter/.local/share/jupyter/runtime \
             /home/jupyter/work \
             /root/.jupyter && \
    chown -R jupyter:users /home/jupyter

# 7. Create Jupyter config
RUN echo "c = get_config()" > /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.token = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/

# 8. Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo 'exec jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --allow-root --notebook-dir=/home/jupyter --ServerApp.token="" --ServerApp.password="" --ServerApp.allow_origin="*"' >> /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# 9. Security hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache

# 10. Final verification
RUN echo "=== Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    jupyter --version && \
    jupyter kernelspec list && \
    R -e ".libPaths('/usr/local/lib/R/site-library'); for(p in c('plyr','anomalize','foreach','tidyverse','tibbletime','doParallel','pbapply','dplyr')) cat(p,':',as.character(packageVersion(p)),'\n')"

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080
USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" version="3.0" \
      description="GCP Workbench with R - Alpine (Hardened)"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]