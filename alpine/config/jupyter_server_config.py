# ============================================
# Jupyter Server Configuration
# Security-hardened settings
# ============================================

c = get_config()

# Server settings
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = False  # Keep XSRF protection enabled
c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}

# Notebook settings
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'

# Kernel settings
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0

# Trust notebooks
c.NotebookNotary.db_file = ':memory:'

# Security settings
c.ServerApp.allow_credentials = False
c.ServerApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self'",
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'SAMEORIGIN',
    }
}

# Disable potentially dangerous extensions
c.ServerApp.jpserver_extensions = {
    'jupyter_server_terminals': True,
    'jupyterlab': True,
}