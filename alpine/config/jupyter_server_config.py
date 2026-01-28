# ============================================
# Jupyter Server Configuration
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
c.ServerApp.disable_check_xsrf = False
c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}

# Notebook settings
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'

# Kernel settings
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0

# Trust notebooks
c.NotebookNotary.db_file = ':memory:'