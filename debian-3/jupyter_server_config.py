# jupyter_server_config.py
c = get_config()
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8080
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.allow_root = True
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True