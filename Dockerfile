# ============================================
# Stage 1: Build R packages
# ============================================
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
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
    libpango1.0-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY packages.txt /tmp/packages.txt

RUN R -e "packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores())"

# ============================================
# Stage 2: Final secure runtime image
# ============================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create non-root user
RUN useradd -m -s /bin/bash -u 1000 jupyter

# Install only runtime dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    r-base \
    libcurl4 \
    libssl3 \
    libxml2 \
    libfontconfig1 \
    libfreetype6 \
    libpng16-16 \
    libtiff6 \
    libjpeg62-turbo \
    libharfbuzz0b \
    libfribidi0 \
    libzmq5 \
    libcairo2 \
    libpango-1.0-0 \
    ca-certificates \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/*

# Copy R libraries from builder
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Install secure Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
    'jupyterlab==4.2.4' \
    'notebook==7.2.1' \
    'jupyter-server==2.14.2' \
    'jupyter-server-proxy==4.3.0' \
    'traitlets>=5.14.3' \
    && rm -rf /root/.cache/pip

# Install IRkernel
RUN R -e "install.packages('IRkernel', repos='https://cloud.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)"

# Final cleanup
RUN rm -rf /tmp/* /var/tmp/* /root/.cache

# Security hardening
RUN chmod 755 /home/jupyter && \
    chown -R jupyter:jupyter /home/jupyter

EXPOSE 8080

USER jupyter

WORKDIR /home/jupyter

# Secure Jupyter configuration
RUN mkdir -p /home/jupyter/.jupyter && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.disable_check_xsrf = False" >> /home/jupyter/.jupyter/jupyter_server_config.py

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/status || exit 1

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8080", "--no-browser"]