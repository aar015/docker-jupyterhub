import os
from cdsdashboards.app import CDS_TEMPLATE_PATHS
from cdsdashboards.hubextension import cds_extra_handlers


c = get_config()

########## Hub Settings ##########
# Open In Dashboard View
c.JupyterHub.default_url = '/hub/dashboards'
# Don't Automatically Redirect to Server
c.JupyterHub.redirect_to_server = False
# Give Admins Access to User Servers
c.JupyterHub.admin_access = True
# Allow for Named Servers
c.JupyterHub.allow_named_servers = True
# Tell Hub to Listen to All Containers on Network
c.JupyterHub.hub_ip = '0.0.0.0'
# Persist Cookie Secrets
c.JupyterHub.cookie_secret_file = os.path.join(os.environ.get('DATA_VOLUME_CONTAINER'), 'jupyterhub_cookie_secret')
# Attach Hub Database
c.JupyterHub.db_url = 'postgresql://postgres:{password}@{host}/{db}'.format(
    host=os.environ['POSTGRES_HOST'],
    password=os.environ['POSTGRES_PASSWORD'],
    db=os.environ['POSTGRES_DB'])

########## Docker Spawner ##########
# Use Variable Docker Spawner for Dashboards
c.JupyterHub.spawner_class = 'cdsdashboards.hubextension.spawners.variabledocker.VariableDockerSpawner'
# Define Docker Image to Use for User Containers
c.DockerSpawner.image = os.environ['DOCKER_NOTEBOOK_IMAGE']
# Start Jupyter Lab by Default
c.DockerSpawner.default_url = '/lab'
# Attach User Volumes to Containers
notebook_dir = os.environ.get('DOCKER_NOTEBOOK_DIR')
c.DockerSpawner.notebook_dir = notebook_dir
c.DockerSpawner.volumes = {'jupyterhub-user-{username}': notebook_dir}
# Define Docker Network to Connect To
c.DockerSpawner.network_name = os.environ['DOCKER_NETWORK_NAME']
# Tell User Containers to Connect to Hub at this IP
c.DockerSpawner.hub_ip_connect = os.environ['HUB_HOST']
# Tell User Containers to Use Docker Network Hostnames
c.DockerSpawner.use_internal_hostname = True
# Remove User Containers on Exit
c.DockerSpawner.remove = True
# Pass Debug Parameter to Spawner
c.DockerSpawner.debug = True
# Define Template for Docker Container Name
c.DockerSpawner.name_template = "{prefix}-{username}-{servername}"

########## Authentication ##########
# Use Google OAuth
c.JupyterHub.authenticator_class = 'oauthenticator.GoogleOAuthenticator'
# Create One Admin User
c.Authenticator.allowed_users = {os.environ.get('ADMIN_USER')}
c.Authenticator.admin_users = {os.environ.get('ADMIN_USER')}

########## Dashboards ##########
c.JupyterHub.template_paths = CDS_TEMPLATE_PATHS
c.JupyterHub.extra_handlers = cds_extra_handlers
c.CDSDashboardsConfig.builder_class = 'cdsdashboards.builder.dockerbuilder.DockerBuilder'