# ============================================
# Stage 1: Build R packages
# ============================================
FROM alpine:3.20 AS builder

ENV CFLAGS="-w -O2"
ENV CXXFLAGS="-w -O2"

# Install R and build dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    R \
    R-dev \
    curl-dev \
    openssl-dev \
    libxml2-dev \
    fontconfig-dev \
    freetype-dev \
    libpng-dev \
    tiff-dev \
    jpeg-dev \
    harfbuzz-dev \
    fribidi-dev \
    zeromq-dev \
    cairo-dev \
    pango-dev \
    linux-headers \
    build-base \
    pkgconfig

COPY packages.txt /tmp/packages.txt

# Install R packages
RUN R --quiet -e "\
    options(warn = -1); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores(), quiet=TRUE)" 2>/dev/null || true

# Install IRkernel R package
RUN R --quiet -e "install.packages('IRkernel', repos='https://cloud.r-project.org', quiet=TRUE)" 2>/dev/null || true

# ============================================
# Stage 2: Final GCP Workbench Compatible Image
# ============================================
FROM alpine:3.20

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash

# Create jupyter user with GID 100 (users group) - required by GCP Workbench
RUN addgroup -g 100 users || true && \
    adduser -D -u 1000 -G users -s /bin/bash jupyter && \
    mkdir -p /home/jupyter && \
    chown -R jupyter:users /home/jupyter

# Install runtime dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    python3 \
    py3-pip \
    R \
    curl \
    openssl \
    libxml2 \
    fontconfig \
    freetype \
    libpng \
    tiff \
    jpeg \
    harfbuzz \
    fribidi \
    zeromq \
    cairo \
    pango \
    ca-certificates \
    wget \
    bash \
    procps

# Copy R libraries from builder
COPY --from=builder /usr/lib/R/library /usr/lib/R/library

# Install Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
    'jupyterlab>=4.0.0,<5.0.0' \
    'notebook>=7.0.0,<8.0.0' \
    'jupyter-server>=2.0.0,<3.0.0' \
    'jupyter-server-proxy' \
    'traitlets'

# Run IRkernel::installspec
RUN R --quiet -e "IRkernel::installspec(user = FALSE)" 2>/dev/null || true

# Create Jupyter configuration directory
RUN mkdir -p /home/jupyter/.jupyter && \
    chown -R jupyter:users /home/jupyter/.jupyter

# GCP Workbench Jupyter configuration
RUN echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.token = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.base_url = '/'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    chown jupyter:users /home/jupyter/.jupyter/jupyter_server_config.py

# Create startup script for GCP Workbench
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo 'exec jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --ServerApp.token="" --ServerApp.password="" --ServerApp.allow_origin="*" --ServerApp.allow_remote_access=True' >> /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# Cleanup
RUN rm -rf /tmp/* /var/tmp/* /root/.cache /var/cache/apk/*

# Set proper permissions
RUN chmod 755 /home/jupyter && \
    chown -R jupyter:users /home/jupyter

# Expose port 8080 (required by GCP Workbench)
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use startup script as entrypoint
ENTRYPOINT ["/usr/local/bin/start-jupyter.sh"]