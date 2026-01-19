# ============================================
# GCP Workbench Jupyter Server Configuration
# Optimized for Wolfi/Chainguard Security
# ============================================

c = get_config()  # noqa

# ===========================================
# Server Network Settings
# ===========================================
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False

# ===========================================
# Authentication
# GCP Workbench uses IAP for authentication
# Token/password disabled - IAP handles auth
# ===========================================
c.ServerApp.token = ''
c.ServerApp.password = ''
c.PasswordIdentityProvider.hashed_password = ''

# ===========================================
# CORS and Remote Access
# Required for GCP Workbench proxy
# ===========================================
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_credentials = True

# Trust X-Forwarded headers from GCP proxy
c.ServerApp.trust_xheaders = True

# ===========================================
# Security Settings
# ===========================================
# Keep XSRF protection enabled
c.ServerApp.disable_check_xsrf = False

# WebSocket settings
c.ServerApp.websocket_compression_options = {}

# ===========================================
# Directory Settings
# ===========================================
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'
c.ServerApp.preferred_dir = '/home/jupyter/work'

# ===========================================
# Terminal Settings
# ===========================================
c.ServerApp.terminals_enabled = True

# ===========================================
# Kernel Management
# Disable idle culling - GCP manages lifecycle
# ===========================================
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0
c.MappingKernelManager.cull_connected = False
c.MappingKernelManager.cull_busy = False

# ===========================================
# File and Contents Settings
# ===========================================
c.ContentsManager.allow_hidden = True

# ===========================================
# Logging
# ===========================================
c.ServerApp.log_level = 'INFO'

# ===========================================
# JupyterLab Settings
# ===========================================
c.LabApp.expose_app_in_browser = True

# ===========================================
# Session Settings
# ===========================================
c.SessionManager.kernel_culling_interval = 0