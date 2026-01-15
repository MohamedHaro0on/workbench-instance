FROM python:3.12-alpine3.20

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create jupyter user
RUN adduser -D -u 1000 jupyter && \
    mkdir -p /home/jupyter && \
    chown -R jupyter:jupyter /home/jupyter

# Install R and system dependencies
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
    linux-headers \
    build-base \
    libffi-dev \
    && rm -rf /var/cache/apk/*

# Install secure Python packages
RUN pip install --no-cache-dir \
    'jupyterlab>=4.1.0' \
    'notebook>=7.1.0' \
    'jupyter-server-proxy>=4.1.1' \
    'jupyter-server>=2.12.5'

# Install IRkernel
RUN R -e "install.packages('IRkernel', repos='https://cloud.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)"

# Copy and install R packages
COPY packages.txt /tmp/packages.txt

RUN R -e "packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores())"

# Final cleanup
RUN rm -rf /tmp/* /var/tmp/* /root/.cache

EXPOSE 8080

USER jupyter

WORKDIR /home/jupyter

RUN mkdir -p /home/jupyter/.jupyter && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = True" >> /home/jupyter/.jupyter/jupyter_server_config.py

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8080", "--no-browser"]