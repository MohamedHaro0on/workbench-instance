FROM gcr.io/deeplearning-platform-release/r-cpu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:${PATH}"

USER root

# Accept repository changes and update
RUN apt-get -o Acquire::AllowReleaseInfoChange::Origin=true \
            -o Acquire::AllowReleaseInfoChange::Label=true \
            update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY packages.txt /tmp/packages.txt

RUN R -e "packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '' & !grepl('^#', packages)]; \
    install.packages(packages, repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=parallel::detectCores())"

RUN rm -rf /tmp/* /var/tmp/*

EXPOSE 8080

USER jupyter

WORKDIR /home/jupyter

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8080", "--no-browser", "--allow-root"]