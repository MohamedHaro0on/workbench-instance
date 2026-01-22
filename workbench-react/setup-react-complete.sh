#!/bin/bash
# Complete React Project Setup for GCP Workbench
# Usage: ./setup-react-complete.sh <project-name> [port]

set -e

PROJECT_NAME="${1:-my-react-app}"
PORT="${2:-3000}"
BASE_DIR="/home/jupyter/react-apps"
PROJECT_DIR="${BASE_DIR}/${PROJECT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     GCP Workbench - React Development Setup                ║"
echo "║     Using Yarn (Secure Package Manager)                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Project: ${PROJECT_NAME}${NC}"
echo -e "${YELLOW}Port: ${PORT}${NC}"
echo -e "${YELLOW}Directory: ${PROJECT_DIR}${NC}"
echo ""

# Check if Yarn is available
if ! command -v yarn &> /dev/null; then
    echo -e "${RED}ERROR: Yarn is not installed${NC}"
    exit 1
fi

# Check if directory exists
if [ -d "${PROJECT_DIR}" ]; then
    echo -e "${YELLOW}WARNING: Directory already exists!${NC}"
    read -p "Remove and recreate? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "${PROJECT_DIR}"
    else
        echo "Aborted."
        exit 1
    fi
fi

# Create base directory
mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}"

echo -e "${GREEN}Creating React project with Vite...${NC}"
echo ""

# Create Vite + React project using Yarn
yarn create vite "${PROJECT_NAME}" --template react

cd "${PROJECT_DIR}"

echo ""
echo -e "${GREEN}Installing dependencies...${NC}"
yarn install

# Create .env file
cat > .env << EOF
VITE_PORT=${PORT}
VITE_APP_NAME=${PROJECT_NAME}
EOF

# Create .env.local for local overrides
cat > .env.local << EOF
# Local environment overrides (not committed to git)
VITE_PORT=${PORT}
EOF

# Create optimized vite.config.js
cat > vite.config.js << 'VITECONFIG'
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const port = parseInt(env.VITE_PORT) || 3000

  return {
    plugins: [react()],
    
    server: {
      port: port,
      host: '0.0.0.0',
      strictPort: true,
      
      // HMR for GCP Workbench proxy
      hmr: {
        protocol: 'wss',
        clientPort: 443,
        overlay: true,
      },
      
      // CORS settings
      cors: true,
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
      
      // File watching (polling for containers)
      watch: {
        usePolling: true,
        interval: 1000,
      },
    },
    
    build: {
      outDir: 'dist',
      sourcemap: true,
    },
    
    resolve: {
      alias: {
        '@': '/src',
        '@components': '/src/components',
        '@hooks': '/src/hooks',
        '@utils': '/src/utils',
      },
    },
  }
})
VITECONFIG

# Create directory structure
mkdir -p src/components
mkdir -p src/hooks
mkdir -p src/utils
mkdir -p src/styles

# Create a sample component
cat > src/components/Welcome.jsx << 'COMPONENT'
import { useState, useEffect } from 'react'

function Welcome() {
  const [time, setTime] = useState(new Date().toLocaleTimeString())
  
  useEffect(() => {
    const timer = setInterval(() => {
      setTime(new Date().toLocaleTimeString())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  return (
    <div className="welcome-container">
      <h1>🚀 React on GCP Workbench</h1>
      <p>Your development environment is ready!</p>
      <p className="time">Current time: {time}</p>
      <div className="features">
        <h3>Features:</h3>
        <ul>
          <li>✅ Hot Module Replacement (HMR)</li>
          <li>✅ Vite for fast builds</li>
          <li>✅ Yarn package manager</li>
          <li>✅ Accessible via Workbench proxy</li>
        </ul>
      </div>
      <p className="edit-hint">
        Edit <code>src/components/Welcome.jsx</code> and save to see changes!
      </p>
    </div>
  )
}

export default Welcome
COMPONENT

# Update App.jsx
cat > src/App.jsx << 'APPJSX'
import Welcome from './components/Welcome'
import './App.css'

function App() {
  return (
    <div className="App">
      <Welcome />
    </div>
  )
}

export default App
APPJSX

# Update App.css
cat > src/App.css << 'APPCSS'
.App {
  text-align: center;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
}

.welcome-container {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 40px;
  max-width: 600px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 10px;
}

.time {
  font-size: 1.5rem;
  font-weight: bold;
  color: #ffd700;
  margin: 20px 0;
}

.features {
  text-align: left;
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 10px;
  margin: 20px 0;
}

.features ul {
  list-style: none;
  padding: 0;
}

.features li {
  padding: 8px 0;
  font-size: 1.1rem;
}

.edit-hint {
  margin-top: 30px;
  padding: 15px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 10px;
}

code {
  background: rgba(255, 255, 255, 0.2);
  padding: 3px 8px;
  border-radius: 5px;
  font-family: 'Monaco', 'Courier New', monospace;
}
APPCSS

# Create start scripts
cat > start-dev.sh << STARTSCRIPT
#!/bin/bash
export HOST=0.0.0.0
export PORT=${PORT}
export VITE_PORT=${PORT}

echo "============================================"
echo "  Starting React Dev Server"
echo "  Port: ${PORT}"
echo "============================================"
echo ""
echo "Access your app at:"
echo "  {workbench-url}/proxy/${PORT}/"
echo ""
echo "Press Ctrl+C to stop"
echo ""

yarn dev --host 0.0.0.0 --port ${PORT}
STARTSCRIPT
chmod +x start-dev.sh

# Create background start script
cat > start-background.sh << BGSCRIPT
#!/bin/bash
export VITE_PORT=${PORT}
LOGFILE="/tmp/react-${PROJECT_NAME}.log"
PIDFILE="/tmp/react-${PROJECT_NAME}.pid"

if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
    echo "Server already running. PID: \$(cat \$PIDFILE)"
    echo "Stop with: ./stop-dev.sh"
    exit 1
fi

echo "Starting React dev server in background..."
nohup yarn dev --host 0.0.0.0 --port ${PORT} > "\$LOGFILE" 2>&1 &
echo \$! > "\$PIDFILE"

sleep 3

if kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
    echo "✅ Server started successfully!"
    echo "   PID: \$(cat \$PIDFILE)"
    echo "   Logs: tail -f \$LOGFILE"
    echo "   Access: {workbench-url}/proxy/${PORT}/"
else
    echo "❌ Failed to start server"
    cat "\$LOGFILE"
    exit 1
fi
BGSCRIPT
chmod +x start-background.sh

# Create stop script
cat > stop-dev.sh << STOPSCRIPT
#!/bin/bash
PIDFILE="/tmp/react-${PROJECT_NAME}.pid"

if [ -f "\$PIDFILE" ]; then
    PID=\$(cat "\$PIDFILE")
    if kill -0 "\$PID" 2>/dev/null; then
        kill "\$PID"
        rm -f "\$PIDFILE"
        echo "✅ Server stopped"
    else
        echo "Process not running"
        rm -f "\$PIDFILE"
    fi
else
    echo "No server running for ${PROJECT_NAME}"
fi
STOPSCRIPT
chmod +x stop-dev.sh

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Dependencies
node_modules/
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/sdks
!.yarn/versions

# Build output
dist/
build/

# Environment
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage/

# Misc
*.pid
GITIGNORE

# Create README
cat > README.md << README
# ${PROJECT_NAME}

React application running on GCP Workbench.

## Quick Start

\`\`\`bash
# Start development server
./start-dev.sh

# Or start in background
./start-background.sh

# Stop background server
./stop-dev.sh
\`\`\`

## Access

Open in browser: \`{workbench-url}/proxy/${PORT}/\`

## Development

- Edit files in \`src/\` directory
- Changes will hot-reload automatically
- Use the terminal in JupyterLab for commands

## Available Scripts

| Script | Description |
|--------|-------------|
| \`yarn dev\` | Start development server |
| \`yarn build\` | Build for production |
| \`yarn preview\` | Preview production build |

## Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/
│   ├── components/    # React components
│   ├── hooks/         # Custom hooks
│   ├── utils/         # Utility functions
│   ├── styles/        # CSS/SCSS files
│   ├── App.jsx        # Main app component
│   └── main.jsx       # Entry point
├── public/            # Static assets
├── .env               # Environment variables
└── vite.config.js     # Vite configuration
\`\`\`
README

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ React Project Created Successfully!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Project Location:${NC} ${PROJECT_DIR}"
echo ""
echo -e "${YELLOW}To start development:${NC}"
echo "  cd ${PROJECT_DIR}"
echo "  ./start-dev.sh"
echo ""
echo -e "${YELLOW}Or start in background:${NC}"
echo "  ./start-background.sh"
echo ""
echo -e "${YELLOW}Access your app at:${NC}"
echo "  {workbench-url}/proxy/${PORT}/"
echo ""