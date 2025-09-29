# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.

server "133.167.120.189", 
  user: "ubuntu",
  roles: %w{app db web},
  ssh_options: {
    keys: %w(~/.ssh/id_ed25519),
    forward_agent: true,
    auth_methods: %w(publickey)
  }

# Set Rails environment to production
set :rails_env, 'production'

# Database configuration
set :pg_database, 'clean_hy_app_production'
set :pg_username, 'clean_hy_app'

# Environment variables
set :default_env, {
  'RAILS_ENV' => 'production',
  'NODE_ENV' => 'production'
}
