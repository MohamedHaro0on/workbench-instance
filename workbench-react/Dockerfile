# ============================================
# GCP Workbench - Alpine Linux (Hardened)
# With React Development Support (Yarn)
# Security Fixes Applied:
#   - CVE-2025-53000: nbconvert Windows path traversal
#   - CVE-2025-8869: pip tar extraction symlink
#   - CVE-2026-23949: jaraco.context path traversal
#   - CVE-2025-59842: JupyterLab LaTeX noopener
# ============================================

# ============================================
# Stage 1: Build Stage
# ============================================
FROM alpine:3.21 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 1. Install Build Dependencies (including Node.js)
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
    # Node.js for React development
    nodejs \
    yarn

# 2. Configure R directories
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library

# 3. Create R Packages List
RUN echo "dplyr" > /tmp/packages.txt && \
    echo "tibble" >> /tmp/packages.txt && \
    echo "tidyr" >> /tmp/packages.txt && \
    echo "readr" >> /tmp/packages.txt && \
    echo "purrr" >> /tmp/packages.txt && \
    echo "stringr" >> /tmp/packages.txt && \
    echo "forcats" >> /tmp/packages.txt && \
    echo "ggplot2" >> /tmp/packages.txt && \
    echo "data.table" >> /tmp/packages.txt && \
    echo "jsonlite" >> /tmp/packages.txt && \
    echo "foreach" >> /tmp/packages.txt && \
    echo "doParallel" >> /tmp/packages.txt

# 4. Install R Packages
RUN R -e "\
    install_repo <- 'https://cloud.r-project.org'; \
    options(repos = c(CRAN = install_repo)); \
    packages <- readLines('/tmp/packages.txt'); \
    packages <- trimws(packages); \
    packages <- packages[packages != '']; \
    for (pkg in packages) { \
        cat('Installing:', pkg, '\n'); \
        tryCatch({ \
            install.packages(pkg, lib='/usr/local/lib/R/site-library', repos=install_repo, dependencies=TRUE, Ncpus=parallel::detectCores()); \
        }, error = function(e) { \
            cat('WARNING: Failed to install', pkg, '\n'); \
        }); \
    }; \
    install.packages('IRkernel', lib='/usr/local/lib/R/site-library', repos=install_repo, dependencies=TRUE);"

# 5. Create Python venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 6. Upgrade pip first to fix CVE-2025-8869
RUN pip install --no-cache-dir --upgrade "pip>=25.3"

# 7. Upgrade setuptools to fix CVE-2026-23949 (jaraco.context)
RUN pip install --no-cache-dir --upgrade "setuptools>=78.1.1"

# 8. Install Jupyter packages with security patches + proxy support
RUN pip install --no-cache-dir --upgrade wheel && \
    pip install --no-cache-dir \
        "jupyterlab>=4.4.8" \
        "notebook>=7.4.2" \
        "jupyter-server>=2.15.0" \
        "jupyter-server-proxy>=4.4.0" \
        "traitlets>=5.14.3" \
        "nbconvert>=7.16.6" \
        "jaraco.context>=6.0.1" \
        ipykernel \
        ipywidgets \
        # Additional proxy packages for React
        "simpervisor>=1.0.0" \
        "aiohttp>=3.9.0"

# 9. Verify security patches
RUN echo "=== Security Patch Verification ===" && \
    pip show pip | grep -E "^Version:" && \
    pip show setuptools | grep -E "^Version:" && \
    pip show jupyterlab | grep -E "^Version:" && \
    pip show nbconvert | grep -E "^Version:" && \
    pip show jaraco.context | grep -E "^Version:" && \
    pip show jupyter-server-proxy | grep -E "^Version:" && \
    echo "=== Verification Complete ==="

# ============================================
# Stage 2: Final Runtime
# ============================================
FROM alpine:3.21

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/home/jupyter

# Yarn configuration - disable npm completely
ENV YARN_IGNORE_NODE=1
ENV npm_config_ignore_scripts=true

# 1. Install Runtime Dependencies (including Node.js and Yarn)
RUN apk update && apk upgrade && apk add --no-cache \
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
    # Node.js and Yarn for React
    nodejs \
    yarn \
    git \
    && rm -rf /var/cache/apk/*

# 2. Create non-root user
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# 3. Copy artifacts from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# 4. Configure R Runtime
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site

# 5. Install R Kernel Spec (system-wide)
RUN R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R (Alpine)')"

# 6. Setup Directories
RUN mkdir -p /home/jupyter/.jupyter && \
    mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.local/share/jupyter/runtime && \
    mkdir -p /home/jupyter/work && \
    mkdir -p /home/jupyter/react-apps && \
    mkdir -p /root/.jupyter && \
    mkdir -p /root/.local/share/jupyter/kernels && \
    mkdir -p /root/.local/share/jupyter/runtime && \
    # Yarn cache directory
    mkdir -p /home/jupyter/.cache/yarn && \
    chown -R jupyter:users /home/jupyter && \
    chmod 755 /home/jupyter

# 7. Configure Yarn globally (safer than npm)
RUN yarn config set --home enableTelemetry false && \
    yarn config set --home nodeLinker node-modules

# 8. Create Jupyter Configuration with Proxy Support
RUN printf '%s\n' \
    'c = get_config()' \
    '' \
    '# Network settings' \
    'c.ServerApp.ip = "0.0.0.0"' \
    'c.ServerApp.port = 8080' \
    'c.ServerApp.open_browser = False' \
    '' \
    '# Authentication (disabled for GCP proxy)' \
    'c.ServerApp.token = ""' \
    'c.ServerApp.password = ""' \
    '' \
    '# Root execution (GCP Workbench runs as root)' \
    'c.ServerApp.allow_root = True' \
    '' \
    '# Remote access settings' \
    'c.ServerApp.allow_origin = "*"' \
    'c.ServerApp.allow_remote_access = True' \
    'c.ServerApp.allow_credentials = True' \
    'c.ServerApp.disable_check_xsrf = True' \
    'c.ServerApp.trust_xheaders = True' \
    '' \
    '# Directory settings' \
    'c.ServerApp.root_dir = "/home/jupyter"' \
    'c.ServerApp.notebook_dir = "/home/jupyter"' \
    '' \
    '# Features' \
    'c.ServerApp.terminals_enabled = True' \
    'c.MappingKernelManager.cull_idle_timeout = 0' \
    'c.MappingKernelManager.cull_interval = 0' \
    'c.ContentsManager.allow_hidden = True' \
    '' \
    '# ============================================' \
    '# Jupyter Server Proxy Configuration for React' \
    '# ============================================' \
    'c.ServerProxy.servers = {' \
    '    "react": {' \
    '        "command": None,' \
    '        "port": 3000,' \
    '        "absolute_url": False,' \
    '        "timeout": 30,' \
    '        "launcher_entry": {' \
    '            "enabled": True,' \
    '            "title": "React Dev Server",' \
    '            "icon_path": None' \
    '        }' \
    '    },' \
    '    "react-alt": {' \
    '        "command": None,' \
    '        "port": 3001,' \
    '        "absolute_url": False,' \
    '        "timeout": 30,' \
    '        "launcher_entry": {' \
    '            "enabled": True,' \
    '            "title": "React Dev Server (Alt)"' \
    '        }' \
    '    }' \
    '}' \
    > /home/jupyter/.jupyter/jupyter_server_config.py && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py

# 9. Create React App Setup Script
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    'APP_NAME="${1:-my-react-app}"' \
    'PORT="${2:-3000}"' \
    'APP_DIR="/home/jupyter/react-apps/${APP_NAME}"' \
    '' \
    'echo "============================================"' \
    'echo "  Creating React App: ${APP_NAME}"' \
    'echo "  Port: ${PORT}"' \
    'echo "============================================"' \
    '' \
    '# Check if directory exists' \
    'if [ -d "${APP_DIR}" ]; then' \
    '    echo "WARNING: Directory ${APP_DIR} already exists!"' \
    '    read -p "Overwrite? (y/N): " confirm' \
    '    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then' \
    '        echo "Aborted."' \
    '        exit 1' \
    '    fi' \
    '    rm -rf "${APP_DIR}"' \
    'fi' \
    '' \
    'mkdir -p "/home/jupyter/react-apps"' \
    'cd /home/jupyter/react-apps' \
    '' \
    'echo ""' \
    'echo "Creating React app with Yarn (Vite)..."' \
    'echo ""' \
    '' \
    '# Use Vite (faster and more secure than CRA)' \
    'yarn create vite "${APP_NAME}" --template react' \
    '' \
    'cd "${APP_DIR}"' \
    '' \
    'echo ""' \
    'echo "Installing dependencies..."' \
    'yarn install' \
    '' \
    '# Create environment file for GCP Workbench proxy' \
    'cat > .env << EOF' \
    'VITE_PORT=${PORT}' \
    'EOF' \
    '' \
    '# Update vite.config.js for GCP Workbench compatibility' \
    'cat > vite.config.js << '\''VITECONFIG'\''' \
    'import { defineConfig } from '\''vite'\''' \
    'import react from '\''@vitejs/plugin-react'\''' \
    '' \
    'export default defineConfig({' \
    '  plugins: [react()],' \
    '  server: {' \
    '    port: parseInt(process.env.VITE_PORT) || 3000,' \
    '    host: "0.0.0.0",' \
    '    strictPort: true,' \
    '    // HMR configuration for GCP Workbench proxy' \
    '    hmr: {' \
    '      // Use WebSocket through the proxy' \
    '      clientPort: 443,' \
    '      protocol: '\''wss'\'',' \
    '      // The path will be handled by jupyter-server-proxy' \
    '      path: '\''/@vite/client'\''' \
    '    },' \
    '    // Allow connections from the proxy' \
    '    cors: true,' \
    '    headers: {' \
    '      '\''Access-Control-Allow-Origin'\'': '\''*'\''' \
    '    }' \
    '  },' \
    '  // Base path for proxy' \
    '  base: '\''./'\'',' \
    '  build: {' \
    '    outDir: '\''dist'\'',' \
    '    sourcemap: true' \
    '  }' \
    '})' \
    'VITECONFIG' \
    '' \
    '# Create start script with proper configuration' \
    'cat > start-dev.sh << '\''STARTSCRIPT'\''' \
    '#!/bin/bash' \
    'export HOST=0.0.0.0' \
    'export PORT=${VITE_PORT:-3000}' \
    'echo "Starting React dev server on port $PORT..."' \
    'echo "Access via: {workbench-url}/proxy/${PORT}/"' \
    'yarn dev --host 0.0.0.0 --port $PORT' \
    'STARTSCRIPT' \
    'chmod +x start-dev.sh' \
    '' \
    'echo ""' \
    'echo "============================================"' \
    'echo "  React App Created Successfully!"' \
    'echo "============================================"' \
    'echo ""' \
    'echo "Location: ${APP_DIR}"' \
    'echo ""' \
    'echo "To start development:"' \
    'echo "  cd ${APP_DIR}"' \
    'echo "  ./start-dev.sh"' \
    'echo ""' \
    'echo "Access your app at:"' \
    'echo "  {workbench-url}/proxy/${PORT}/"' \
    'echo ""' \
    > /usr/local/bin/create-react-app.sh && \
    chmod +x /usr/local/bin/create-react-app.sh

# 10. Create React Dev Server Manager Script
RUN printf '%s\n' \
    '#!/bin/bash' \
    '' \
    'ACTION="${1:-help}"' \
    'APP_PATH="${2}"' \
    'PORT="${3:-3000}"' \
    '' \
    'PIDFILE="/tmp/react-dev-${PORT}.pid"' \
    'LOGFILE="/tmp/react-dev-${PORT}.log"' \
    '' \
    'case "$ACTION" in' \
    '    start)' \
    '        if [ -z "$APP_PATH" ]; then' \
    '            echo "Usage: react-dev start /path/to/app [port]"' \
    '            exit 1' \
    '        fi' \
    '        ' \
    '        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then' \
    '            echo "React dev server already running on port ${PORT}"' \
    '            exit 1' \
    '        fi' \
    '        ' \
    '        cd "$APP_PATH"' \
    '        echo "Starting React dev server..."' \
    '        nohup yarn dev --host 0.0.0.0 --port "$PORT" > "$LOGFILE" 2>&1 &' \
    '        echo $! > "$PIDFILE"' \
    '        sleep 2' \
    '        ' \
    '        if kill -0 $(cat "$PIDFILE") 2>/dev/null; then' \
    '            echo "React dev server started on port ${PORT}"' \
    '            echo "Access at: {workbench-url}/proxy/${PORT}/"' \
    '            echo "Logs: tail -f $LOGFILE"' \
    '        else' \
    '            echo "Failed to start server. Check $LOGFILE"' \
    '            exit 1' \
    '        fi' \
    '        ;;' \
    '    ' \
    '    stop)' \
    '        if [ -f "$PIDFILE" ]; then' \
    '            PID=$(cat "$PIDFILE")' \
    '            if kill -0 "$PID" 2>/dev/null; then' \
    '                kill "$PID"' \
    '                rm -f "$PIDFILE"' \
    '                echo "React dev server stopped"' \
    '            else' \
    '                echo "Process not running"' \
    '                rm -f "$PIDFILE"' \
    '            fi' \
    '        else' \
    '            echo "No PID file found for port ${PORT}"' \
    '        fi' \
    '        ;;' \
    '    ' \
    '    status)' \
    '        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then' \
    '            echo "React dev server is running on port ${PORT}"' \
    '            echo "PID: $(cat $PIDFILE)"' \
    '        else' \
    '            echo "React dev server is not running on port ${PORT}"' \
    '        fi' \
    '        ;;' \
    '    ' \
    '    logs)' \
    '        if [ -f "$LOGFILE" ]; then' \
    '            tail -f "$LOGFILE"' \
    '        else' \
    '            echo "No log file found"' \
    '        fi' \
    '        ;;' \
    '    ' \
    '    *)' \
    '        echo "React Dev Server Manager"' \
    '        echo ""' \
    '        echo "Usage: react-dev <command> [options]"' \
    '        echo ""' \
    '        echo "Commands:"' \
    '        echo "  start <app-path> [port]  Start dev server"' \
    '        echo "  stop [port]              Stop dev server"' \
    '        echo "  status [port]            Check server status"' \
    '        echo "  logs [port]              View server logs"' \
    '        echo ""' \
    '        echo "Default port: 3000"' \
    '        ;;' \
    'esac' \
    > /usr/local/bin/react-dev && \
    chmod +x /usr/local/bin/react-dev

# 11. Create Startup Script
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    'echo "============================================"' \
    'echo "  GCP Workbench - Starting Jupyter"' \
    'echo "  React Development Environment Ready"' \
    'echo "============================================"' \
    'echo "User: $(whoami)"' \
    'echo "UID: $(id -u)"' \
    'echo "GID: $(id -g)"' \
    'echo "Python: $(python3 --version 2>&1)"' \
    'echo "R: $(R --version 2>&1 | head -1)"' \
    'echo "Node.js: $(node --version 2>&1)"' \
    'echo "Yarn: $(yarn --version 2>&1)"' \
    '' \
    '# Ensure directories exist' \
    'mkdir -p ~/.local/share/jupyter/kernels' \
    'mkdir -p ~/.local/share/jupyter/runtime' \
    'mkdir -p ~/.jupyter' \
    'mkdir -p ~/react-apps' \
    '' \
    '# Copy config if running as root' \
    'if [ "$(id -u)" = "0" ] && [ ! -f /root/.jupyter/jupyter_server_config.py ]; then' \
    '    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/ 2>/dev/null || true' \
    'fi' \
    '' \
    'echo ""' \
    'echo "Available kernels:"' \
    'jupyter kernelspec list' \
    '' \
    'echo ""' \
    'echo "============================================"' \
    'echo "  React Development Quick Start"' \
    'echo "============================================"' \
    'echo ""' \
    'echo "1. Create a new React app:"' \
    'echo "   create-react-app.sh my-app 3000"' \
    'echo ""' \
    'echo "2. Start dev server:"' \
    'echo "   cd ~/react-apps/my-app && ./start-dev.sh"' \
    'echo "   OR"' \
    'echo "   react-dev start ~/react-apps/my-app 3000"' \
    'echo ""' \
    'echo "3. Access your app:"' \
    'echo "   {workbench-url}/proxy/3000/"' \
    'echo ""' \
    'echo "============================================"' \
    'echo ""' \
    'echo "Starting JupyterLab on port 8080..."' \
    'echo ""' \
    '' \
    'exec jupyter lab \' \
    '    --ip=0.0.0.0 \' \
    '    --port=8080 \' \
    '    --no-browser \' \
    '    --notebook-dir=/home/jupyter \' \
    '    --ServerApp.token="" \' \
    '    --ServerApp.password="" \' \
    '    --ServerApp.allow_origin="*" \' \
    '    --ServerApp.allow_remote_access=True \' \
    '    --ServerApp.allow_root=True \' \
    '    --allow-root' \
    > /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# 12. Security Hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true && \
    rm -rf /tmp/* /var/tmp/* /root/.cache 2>/dev/null || true

# 13. Final Verification
RUN echo "=== Final Verification ===" && \
    python3 --version && \
    R --version | head -1 && \
    node --version && \
    yarn --version && \
    jupyter --version && \
    jupyter kernelspec list && \
    echo "" && \
    echo "=== Security Package Versions ===" && \
    pip show pip | grep -E "^Version:" && \
    pip show setuptools | grep -E "^Version:" && \
    pip show jupyterlab | grep -E "^Version:" && \
    pip show nbconvert | grep -E "^Version:" && \
    pip show jupyter-server-proxy | grep -E "^Version:" && \
    echo "=== Verification Complete ==="

# 14. Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080 3000 3001

USER jupyter
WORKDIR /home/jupyter

LABEL maintainer="mohamedharoon0" \
      version="2.0" \
      description="GCP Workbench with R & React Development - Alpine Linux (Secure)" \
      features="react,yarn,vite,hot-reload,jupyter-proxy" \
      security.cve-2025-53000="patched" \
      security.cve-2025-8869="patched" \
      security.cve-2026-23949="patched" \
      security.cve-2025-59842="patched"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]