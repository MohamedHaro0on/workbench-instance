FROM gcr.io/deeplearning-platform-release/workbench-container:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SHELL=/bin/bash

USER root

# Fix repository issues and update
RUN rm -f /etc/apt/sources.list.d/gcsfuse.list || true && \
    rm -f /etc/apt/sources.list.d/google-cloud*.list || true && \
    apt-get update -o Acquire::AllowReleaseInfoChange::Origin=true \
                   -o Acquire::AllowReleaseInfoChange::Label=true || \
    apt-get update && \
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
    pkg-config \
    make \
    gcc \
    g++ \
    curl \
    wget \
    bash \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install IRkernel for Jupyter R support
RUN R --quiet -e "install.packages('IRkernel', repos='https://cloud.r-project.org', quiet=TRUE)" && \
    R --quiet -e "IRkernel::installspec(user = FALSE)"

# Copy and install R packages
COPY packages.txt /tmp/packages.txt

RUN R --quiet -e "\
    options(warn = -1); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores(), quiet=TRUE)" 2>/dev/null || true

# Create Jupyter configuration directory
RUN mkdir -p /home/jupyter/.jupyter && \
    chown -R jupyter:users /home/jupyter/.jupyter || true

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
    chown jupyter:users /home/jupyter/.jupyter/jupyter_server_config.py || true

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo 'exec jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --ServerApp.token="" --ServerApp.password="" --ServerApp.allow_origin="*" --ServerApp.allow_remote_access=True' >> /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# Cleanup
RUN rm -rf /tmp/* /var/tmp/* /root/.cache

# Set proper permissions
RUN chmod 755 /home/jupyter && \
    chown -R jupyter:users /home/jupyter || true

# Expose Jupyter port
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Use startup script as entrypoint
ENTRYPOINT ["/usr/local/bin/start-jupyter.sh"]