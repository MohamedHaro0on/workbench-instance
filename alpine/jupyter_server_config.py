# Jupyter Server Configuration for GCP Workbench
c = get_config()

# Network settings
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False

# Authentication (disabled for GCP proxy)
c.ServerApp.token = ''
c.ServerApp.password = ''

# CRITICAL: Allow root execution (GCP Workbench runs as root)
c.ServerApp.allow_root = True

# Remote access settings
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.trust_xheaders = True

# Directory settings
c.ServerApp.root_dir = '/home/jupyter'
c.ServerApp.notebook_dir = '/home/jupyter'

# Features
c.ServerApp.terminals_enabled = True
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0
c.ContentsManager.allow_hidden = True