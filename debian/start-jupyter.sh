#!/bin/bash
set -e

# Ensure proper permissions
mkdir -p /home/jupyter/.local/share/jupyter
mkdir -p /home/jupyter/.cache

exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8080 \
    --no-browser \
    --ServerApp.token="" \
    --ServerApp.password="" \
    --ServerApp.allow_origin="*" \
    --ServerApp.allow_remote_access=True