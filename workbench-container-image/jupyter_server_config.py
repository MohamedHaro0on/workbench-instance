# GCP Workbench Jupyter Server Configuration
c = get_config()

# Server settings
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True

# Disable token/password for GCP Workbench (IAP handles auth)
c.ServerApp.token = ''
c.ServerApp.password = ''

# Security settings
c.ServerApp.disable_check_xsrf = False
c.ServerApp.allow_credentials = True

# Notebook settings
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'

# Terminal settings
c.ServerApp.terminals_enabled = True

# Kernel settings
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0

# File settings
c.ContentsManager.allow_hidden = True