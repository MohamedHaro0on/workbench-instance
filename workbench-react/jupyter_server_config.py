# /home/jupyter/.jupyter/jupyter_server_config.py
# GCP Workbench Jupyter Configuration with React Proxy Support

c = get_config()

# ===========================================
# Network Settings
# ===========================================
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 8080
c.ServerApp.open_browser = False

# ===========================================
# Authentication (disabled for GCP proxy)
# ===========================================
c.ServerApp.token = ""
c.ServerApp.password = ""

# ===========================================
# Root & Remote Access
# ===========================================
c.ServerApp.allow_root = True
c.ServerApp.allow_origin = "*"
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.trust_xheaders = True

# ===========================================
# Directory Settings
# ===========================================
c.ServerApp.root_dir = "/home/jupyter"
c.ServerApp.notebook_dir = "/home/jupyter"

# ===========================================
# Features
# ===========================================
c.ServerApp.terminals_enabled = True
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0
c.ContentsManager.allow_hidden = True

# ===========================================
# Jupyter Server Proxy - React Dev Servers
# ===========================================
c.ServerProxy.servers = {
    # Primary React Dev Server
    "react": {
        "command": None,  # Manual start - user controls the server
        "port": 3000,
        "absolute_url": False,
        "timeout": 30,
        "mappath": {
            "/": "/",
        },
        "launcher_entry": {
            "enabled": True,
            "title": "React App (Port 3000)",
            "icon_path": None,
            "path_info": "react"
        },
        "new_browser_tab": True,
        "request_headers_override": {
            "X-Forwarded-Proto": "https"
        }
    },
    
    # Secondary React Dev Server (for multiple projects)
    "react-3001": {
        "command": None,
        "port": 3001,
        "absolute_url": False,
        "timeout": 30,
        "launcher_entry": {
            "enabled": True,
            "title": "React App (Port 3001)"
        }
    },
    
    # Vite default ports
    "vite": {
        "command": None,
        "port": 5173,
        "absolute_url": False,
        "timeout": 30,
        "launcher_entry": {
            "enabled": True,
            "title": "Vite Dev Server"
        }
    }
}

# ===========================================
# WebSocket Settings (for HMR)
# ===========================================
c.ServerApp.websocket_compression_options = {}