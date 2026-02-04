# ============================================
# Jupyter Server Configuration
# GCP Workbench - R 4.1.0 + Python
# Security-hardened settings
# ============================================

c = get_config()

# ============================================
# Server Settings
# ============================================
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = False  # Keep XSRF protection enabled

# Shell settings
c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}

# ============================================
# Directory Settings
# ============================================
c.ServerApp.notebook_dir = '/home/jupyter'
c.ServerApp.root_dir = '/home/jupyter'

# ============================================
# Kernel Settings
# ============================================
# Don't cull idle kernels (important for long-running R computations)
c.MappingKernelManager.cull_idle_timeout = 0
c.MappingKernelManager.cull_interval = 0
c.MappingKernelManager.cull_connected = False
c.MappingKernelManager.cull_busy = False

# Kernel startup timeout (R kernel may take longer to start)
c.MappingKernelManager.kernel_info_timeout = 60

# Allow multiple connections to same kernel
c.MappingKernelManager.default_kernel_name = 'python3'

# ============================================
# R Kernel Specific Settings
# ============================================
# Increase timeout for R kernel operations
c.KernelManager.shutdown_wait_time = 30

# ============================================
# Notebook Settings
# ============================================
# Trust notebooks (for R markdown output)
c.NotebookNotary.db_file = ':memory:'

# ============================================
# Security Settings
# ============================================
c.ServerApp.allow_credentials = False

c.ServerApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self'",
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'SAMEORIGIN',
    }
}

# ============================================
# Extensions
# ============================================
c.ServerApp.jpserver_extensions = {
    'jupyter_server_terminals': True,
    'jupyterlab': True,
}

# ============================================
# Logging
# ============================================
c.ServerApp.log_level = 'INFO'

# ============================================
# Resource Limits (optional, adjust as needed)
# ============================================
# c.ResourceUseDisplay.mem_limit = 4 * 1024 * 1024 * 1024  # 4GB
# c.ResourceUseDisplay.track_cpu_percent = True

# ============================================
# Contents Manager
# ============================================
# Allow hidden files (like .Rprofile)
c.ContentsManager.allow_hidden = True

# ============================================
# GCP Workbench Specific
# ============================================
# These settings help with GCP Workbench integration
c.ServerApp.base_url = '/'
c.ServerApp.default_url = '/lab'

# Shutdown settings
c.ServerApp.shutdown_no_activity_timeout = 0  # Never auto-shutdown