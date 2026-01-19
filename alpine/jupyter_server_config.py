# GCP Workbench Jupyter Server Configuration
# Optimized for security and GCP IAP authentication

c = get_config()

# ===================
# Server Settings
# ===================
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False

# ===================
# Authentication
# GCP Workbench uses IAP for auth, so we disable token/password
# ===================
c.ServerApp.token = ''
c.ServerApp.password = ''
c.PasswordIdentityProvider.hashed_password = ''

# ===================
# CORS / Remote Access
# Required for GCP Workbench proxy
# ===================
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_credentials = True

# ===================
# Security Settings
# ===================
c.ServerApp.disable_check_xsrf = False  # Keep XSRF protection enabled

# Trust X-Forwarded headers from GCP proxy
c.ServerApp.trust_xheaders = True

# ===================
# Directory Settings
# ===================
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'
c.ServerApp.preferred_dir = '/home/jupyter/work'

# ===================
# Terminal Settings
# ===================
c.ServerApp.terminals_enabled = True

# ===================
# Kernel Settings
# Disable idle culling (GCP manages instance lifecycle)
# ===================
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0
c.MappingKernelManager.cull_connected = False

# ===================
# File Settings
# ===================
c.ContentsManager.allow_hidden = True

# ===================
# Logging
# ===================
c.ServerApp.log_level = 'INFO'

# ===================
# Extension Settings
# ===================
c.LabApp.expose_app_in_browser = True