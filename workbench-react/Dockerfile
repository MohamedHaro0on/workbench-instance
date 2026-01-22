# ============================================
# GCP Workbench - Alpine Linux with React
# ============================================
FROM alpine:3.21 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Enable community repository
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories

# Update with retry
RUN for i in 1 2 3; do apk update && apk upgrade && break || sleep 15; done

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    gfortran \
    linux-headers \
    pkgconf \
    git \
    bash \
    wget \
    curl

# Install R
RUN apk add --no-cache R R-dev R-doc

# Install Python
RUN apk add --no-cache \
    python3 \
    python3-dev \
    py3-pip \
    py3-wheel \
    py3-setuptools

# Install development libraries
RUN apk add --no-cache \
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
    lapack-dev

# Install Node.js only
RUN apk add --no-cache nodejs

# Install Yarn via direct download (no npm needed)
RUN wget -qO- https://github.com/yarnpkg/yarn/releases/download/v1.22.22/yarn-v1.22.22.tar.gz | tar xz -C /opt && \
    ln -s /opt/yarn-v1.22.22/bin/yarn /usr/local/bin/yarn && \
    ln -s /opt/yarn-v1.22.22/bin/yarnpkg /usr/local/bin/yarnpkg

# Verify yarn installation
RUN yarn --version

# Configure R
RUN mkdir -p /usr/local/lib/R/site-library && \
    chmod 755 /usr/local/lib/R/site-library

# Install R Packages
RUN R -e "install.packages(c('dplyr','tibble','tidyr','readr','purrr','stringr','forcats','ggplot2','data.table','jsonlite','foreach','doParallel','IRkernel'), lib='/usr/local/lib/R/site-library', repos='https://cloud.r-project.org', dependencies=TRUE, Ncpus=4)"

# Create Python venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
RUN pip install --no-cache-dir --upgrade "pip>=25.3" && \
    pip install --no-cache-dir --upgrade "setuptools>=78.1.1" && \
    pip install --no-cache-dir --upgrade wheel && \
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
        simpervisor \
        aiohttp

# Build React Application
WORKDIR /opt/react-app

# Create package.json
RUN echo '{"name":"mc2-react-app","private":true,"version":"0.0.0","type":"module","scripts":{"dev":"vite --host 0.0.0.0","build":"vite build","lint":"eslint .","preview":"vite preview --host 0.0.0.0"},"dependencies":{"@emotion/react":"^11.14.0","@emotion/styled":"^11.14.0","@mui/material":"^7.0.0","react":"^19.0.0","react-dom":"^19.0.0","react-icons":"^5.5.0"},"devDependencies":{"@eslint/js":"^9.27.0","@types/react":"^19.0.0","@types/react-dom":"^19.0.0","@vitejs/plugin-react":"^4.5.0","eslint":"^9.27.0","eslint-plugin-react-hooks":"^5.2.0","eslint-plugin-react-refresh":"^0.4.20","globals":"^16.1.0","vite":"^6.3.0"}}' > package.json

# Create vite.config.js
RUN echo "import { defineConfig } from 'vite'" > vite.config.js && \
    echo "import react from '@vitejs/plugin-react'" >> vite.config.js && \
    echo "" >> vite.config.js && \
    echo "export default defineConfig({" >> vite.config.js && \
    echo "  plugins: [react()]," >> vite.config.js && \
    echo "  server: {" >> vite.config.js && \
    echo "    host: '0.0.0.0'," >> vite.config.js && \
    echo "    port: 3000," >> vite.config.js && \
    echo "    strictPort: true," >> vite.config.js && \
    echo "    hmr: { protocol: 'wss', clientPort: 443 }," >> vite.config.js && \
    echo "    cors: true," >> vite.config.js && \
    echo "    watch: { usePolling: true, interval: 1000 }," >> vite.config.js && \
    echo "  }," >> vite.config.js && \
    echo "  preview: { host: '0.0.0.0', port: 3000 }," >> vite.config.js && \
    echo "  build: { outDir: 'dist', sourcemap: true }," >> vite.config.js && \
    echo "  base: './'," >> vite.config.js && \
    echo "})" >> vite.config.js

# Create index.html
RUN echo '<!DOCTYPE html>' > index.html && \
    echo '<html lang="en">' >> index.html && \
    echo '<head>' >> index.html && \
    echo '  <meta charset="UTF-8" />' >> index.html && \
    echo '  <meta name="viewport" content="width=device-width, initial-scale=1.0" />' >> index.html && \
    echo '  <title>MC2 React App</title>' >> index.html && \
    echo '</head>' >> index.html && \
    echo '<body>' >> index.html && \
    echo '  <div id="root"></div>' >> index.html && \
    echo '  <script type="module" src="/src/main.jsx"></script>' >> index.html && \
    echo '</body>' >> index.html && \
    echo '</html>' >> index.html

# Create directories
RUN mkdir -p src public

# Create src/main.jsx
RUN echo "import React from 'react'" > src/main.jsx && \
    echo "import ReactDOM from 'react-dom/client'" >> src/main.jsx && \
    echo "import { ThemeProvider, createTheme } from '@mui/material/styles'" >> src/main.jsx && \
    echo "import CssBaseline from '@mui/material/CssBaseline'" >> src/main.jsx && \
    echo "import App from './App'" >> src/main.jsx && \
    echo "import './index.css'" >> src/main.jsx && \
    echo "" >> src/main.jsx && \
    echo "const theme = createTheme({" >> src/main.jsx && \
    echo "  palette: { mode: 'light', primary: { main: '#1976d2' }, secondary: { main: '#9c27b0' } }," >> src/main.jsx && \
    echo "})" >> src/main.jsx && \
    echo "" >> src/main.jsx && \
    echo "ReactDOM.createRoot(document.getElementById('root')).render(" >> src/main.jsx && \
    echo "  <React.StrictMode>" >> src/main.jsx && \
    echo "    <ThemeProvider theme={theme}>" >> src/main.jsx && \
    echo "      <CssBaseline />" >> src/main.jsx && \
    echo "      <App />" >> src/main.jsx && \
    echo "    </ThemeProvider>" >> src/main.jsx && \
    echo "  </React.StrictMode>," >> src/main.jsx && \
    echo ")" >> src/main.jsx

# Create src/App.jsx
RUN echo "import { useState, useEffect } from 'react'" > src/App.jsx && \
    echo "import { Container, Box, Typography, Button, Card, CardContent, Stack, Chip, Paper } from '@mui/material'" >> src/App.jsx && \
    echo "import { FaReact } from 'react-icons/fa'" >> src/App.jsx && \
    echo "import { SiVite } from 'react-icons/si'" >> src/App.jsx && \
    echo "" >> src/App.jsx && \
    echo "function App() {" >> src/App.jsx && \
    echo "  const [count, setCount] = useState(0)" >> src/App.jsx && \
    echo "  const [time, setTime] = useState(new Date().toLocaleTimeString())" >> src/App.jsx && \
    echo "" >> src/App.jsx && \
    echo "  useEffect(() => {" >> src/App.jsx && \
    echo "    const timer = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000)" >> src/App.jsx && \
    echo "    return () => clearInterval(timer)" >> src/App.jsx && \
    echo "  }, [])" >> src/App.jsx && \
    echo "" >> src/App.jsx && \
    echo "  return (" >> src/App.jsx && \
    echo "    <Box sx={{ minHeight: '100vh', background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', py: 4 }}>" >> src/App.jsx && \
    echo "      <Container maxWidth=\"md\">" >> src/App.jsx && \
    echo "        <Paper elevation={10} sx={{ p: 4, borderRadius: 4 }}>" >> src/App.jsx && \
    echo "          <Box textAlign=\"center\" mb={4}>" >> src/App.jsx && \
    echo "            <Typography variant=\"h3\" fontWeight=\"bold\" gutterBottom>MC2 React App</Typography>" >> src/App.jsx && \
    echo "            <Stack direction=\"row\" spacing={2} justifyContent=\"center\" mb={2}>" >> src/App.jsx && \
    echo "              <FaReact size={40} color=\"#61DAFB\" />" >> src/App.jsx && \
    echo "              <SiVite size={40} color=\"#646CFF\" />" >> src/App.jsx && \
    echo "            </Stack>" >> src/App.jsx && \
    echo "            <Chip label={time} color=\"primary\" />" >> src/App.jsx && \
    echo "          </Box>" >> src/App.jsx && \
    echo "          <Card sx={{ mb: 4, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', color: 'white' }}>" >> src/App.jsx && \
    echo "            <CardContent>" >> src/App.jsx && \
    echo "              <Box textAlign=\"center\">" >> src/App.jsx && \
    echo "                <Typography variant=\"h4\">Counter: {count}</Typography>" >> src/App.jsx && \
    echo "                <Stack direction=\"row\" spacing={2} justifyContent=\"center\" mt={2}>" >> src/App.jsx && \
    echo "                  <Button variant=\"contained\" color=\"inherit\" sx={{ color: '#667eea' }} onClick={() => setCount(c => c - 1)}>-</Button>" >> src/App.jsx && \
    echo "                  <Button variant=\"contained\" color=\"inherit\" sx={{ color: '#764ba2' }} onClick={() => setCount(c => c + 1)}>+</Button>" >> src/App.jsx && \
    echo "                  <Button variant=\"outlined\" color=\"inherit\" onClick={() => setCount(0)}>Reset</Button>" >> src/App.jsx && \
    echo "                </Stack>" >> src/App.jsx && \
    echo "              </Box>" >> src/App.jsx && \
    echo "            </CardContent>" >> src/App.jsx && \
    echo "          </Card>" >> src/App.jsx && \
    echo "          <Typography variant=\"body2\" textAlign=\"center\" color=\"text.secondary\">Edit src/App.jsx and save to test HMR</Typography>" >> src/App.jsx && \
    echo "        </Paper>" >> src/App.jsx && \
    echo "      </Container>" >> src/App.jsx && \
    echo "    </Box>" >> src/App.jsx && \
    echo "  )" >> src/App.jsx && \
    echo "}" >> src/App.jsx && \
    echo "" >> src/App.jsx && \
    echo "export default App" >> src/App.jsx

# Create src/index.css
RUN echo "* { margin: 0; padding: 0; box-sizing: border-box; }" > src/index.css && \
    echo "body { font-family: 'Roboto', sans-serif; }" >> src/index.css

# Install dependencies
RUN yarn install

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.21

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SHELL=/bin/bash
ENV R_LIBS_SITE=/usr/local/lib/R/site-library
ENV PATH="/opt/venv/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV HOME=/home/jupyter

# Enable community repository
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories

# Install Runtime Dependencies
RUN for i in 1 2 3; do apk update && break || sleep 10; done && \
    apk add --no-cache \
    bash \
    tini \
    ca-certificates \
    python3 \
    curl \
    wget \
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
    nodejs \
    git \
    R \
    && rm -rf /var/cache/apk/*

# Install Yarn via direct download (no npm needed)
RUN wget -qO- https://github.com/yarnpkg/yarn/releases/download/v1.22.22/yarn-v1.22.22.tar.gz | tar xz -C /opt && \
    ln -s /opt/yarn-v1.22.22/bin/yarn /usr/local/bin/yarn && \
    ln -s /opt/yarn-v1.22.22/bin/yarnpkg /usr/local/bin/yarnpkg

# Create user
RUN adduser -D -u 1000 -G users -s /bin/bash -h /home/jupyter jupyter

# Copy from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder --chown=jupyter:users /opt/react-app /home/jupyter/react-app

# Configure R
RUN mkdir -p /usr/local/lib/R/site-library && \
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site && \
    echo '.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site && \
    R -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R')"

# Setup directories
RUN mkdir -p /home/jupyter/.jupyter && \
    mkdir -p /home/jupyter/.local/share/jupyter/kernels && \
    mkdir -p /home/jupyter/.local/share/jupyter/runtime && \
    mkdir -p /home/jupyter/work && \
    mkdir -p /root/.jupyter && \
    chown -R jupyter:users /home/jupyter && \
    chmod -R 755 /home/jupyter

# Create Jupyter config
RUN echo "c = get_config()" > /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.port = 8080" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.token = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_credentials = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.disable_check_xsrf = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.trust_xheaders = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.root_dir = '/home/jupyter'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.notebook_dir = '/home/jupyter'" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.terminals_enabled = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.MappingKernelManager.cull_idle_timeout = 0" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    echo "c.ContentsManager.allow_hidden = True" >> /home/jupyter/.jupyter/jupyter_server_config.py && \
    cp /home/jupyter/.jupyter/jupyter_server_config.py /root/.jupyter/ && \
    chmod 644 /home/jupyter/.jupyter/jupyter_server_config.py

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-jupyter.sh && \
    echo 'set -e' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  GCP Workbench - Jupyter + React"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "============================================"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Python: $(python3 --version)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Node: $(node --version)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Yarn: $(yarn --version)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "R: $(R --version | head -1)"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "React app: /home/jupyter/react-app"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Start: cd ~/react-app && yarn dev"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "  Access: http://localhost:3000"' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo ""' >> /usr/local/bin/start-jupyter.sh && \
    echo 'mkdir -p ~/.local/share/jupyter/kernels' >> /usr/local/bin/start-jupyter.sh && \
    echo 'mkdir -p ~/.local/share/jupyter/runtime' >> /usr/local/bin/start-jupyter.sh && \
    echo 'if [ "$(id -u)" = "0" ]; then' >> /usr/local/bin/start-jupyter.sh && \
    echo '    chown -R jupyter:users /home/jupyter 2>/dev/null || true' >> /usr/local/bin/start-jupyter.sh && \
    echo 'fi' >> /usr/local/bin/start-jupyter.sh && \
    echo 'echo "Starting JupyterLab on port 8080..."' >> /usr/local/bin/start-jupyter.sh && \
    echo 'exec jupyter lab --ip=0.0.0.0 --port=8080 --no-browser --notebook-dir=/home/jupyter --ServerApp.token="" --ServerApp.password="" --ServerApp.allow_origin="*" --ServerApp.allow_remote_access=True --ServerApp.allow_root=True --allow-root' >> /usr/local/bin/start-jupyter.sh && \
    chmod +x /usr/local/bin/start-jupyter.sh

# Create React helper script
RUN echo '#!/bin/bash' > /usr/local/bin/start-react.sh && \
    echo 'cd /home/jupyter/react-app' >> /usr/local/bin/start-react.sh && \
    echo 'echo "Starting React on port 3000..."' >> /usr/local/bin/start-react.sh && \
    echo 'exec yarn dev' >> /usr/local/bin/start-react.sh && \
    chmod +x /usr/local/bin/start-react.sh

# Security hardening
RUN find /usr -type f -perm /6000 -exec chmod a-s {} \; 2>/dev/null || true

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

EXPOSE 8080 3000

USER jupyter
WORKDIR /home/jupyter

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-jupyter.sh"]