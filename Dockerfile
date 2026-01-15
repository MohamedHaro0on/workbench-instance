FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create jupyter user for Workbench compatibility
RUN useradd -m -s /bin/bash -u 1000 jupyter && \
    mkdir -p /home/jupyter && \
    chown -R jupyter:jupyter /home/jupyter

USER root

# Install R and system dependencies
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
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libzmq3-dev \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/*

# Install JupyterLab and dependencies
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    jupyter-server-proxy \
    && rm -rf /root/.cache/pip

# Install IRkernel for Jupyter R support
RUN R -e "install.packages('IRkernel', repos='https://cloud.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)"

# Copy and install R packages
COPY packages.txt /tmp/packages.txt

RUN R -e "packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores())"

# Cleanup
RUN rm -rf /tmp/* /var/tmp/*

# Expose Jupyter port
EXPOSE 8080

# Switch to jupyter user
USER jupyter

WORKDIR /home/jupyter

# Configure Jupyter
RUN mkdir -p /home/jupyter/.jupyter && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = True" >> /home/jupyter/.jupyter/jupyter_server_config.py

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8080", "--no-browser"]