# Use the GCP Deep Learning Workbench container as the base image
FROM gcr.io/deeplearning-platform-release/workbench-container:latest

# Set environment variables to avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Define the Python version you want to install
ARG PYTHON_VERSION=3.11
ENV PYTHON_VERSION=${PYTHON_VERSION}

# Switch to root user to install packages
USER root

# Install prerequisites and the deadsnakes PPA (for newer Python versions on Ubuntu/Debian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        python${PYTHON_VERSION}-distutils \
    && rm -rf /var/lib/apt/lists/*

# Install pip for the new Python version
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}

# Update alternatives so `python3` and `python` point to the new version
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --set python3 /usr/bin/python${PYTHON_VERSION} \
    && update-alternatives --set python /usr/bin/python${PYTHON_VERSION}

# Upgrade pip, setuptools, and wheel
RUN python${PYTHON_VERSION} -m pip install --no-cache-dir --upgrade pip setuptools wheel

# (Optional) Install commonly used data science / ML packages on the new Python
RUN python${PYTHON_VERSION} -m pip install --no-cache-dir \
    ipykernel \
    jupyter \
    numpy \
    pandas \
    scikit-learn

# (Optional) Register the new Python as a Jupyter kernel so it appears in Workbench
RUN python${PYTHON_VERSION} -m ipykernel install --name "python${PYTHON_VERSION}" \
    --display-name "Python ${PYTHON_VERSION}"

# Verify installation
RUN python --version && python3 --version && pip --version

# Reset frontend
ENV DEBIAN_FRONTEND=

# Keep the original entrypoint/CMD from the base image (do NOT override)
# The workbench-container base image already defines the proper ENTRYPOINT/CMD