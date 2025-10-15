# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "clean_hy_app"
set :repo_url, "https://github.com/dicea5050/clean_hy_app.git"

# Default branch is :main
set :branch, "main"

# Deploy directory
set :deploy_to, "/var/www/clean_hy_app"

# Ruby version for rbenv
set :rbenv_ruby, "3.3.0"

# Use HTTPS for git operations
set :scm, :git

# Linked files - files that will be symlinked from shared folder
append :linked_files, "config/master.key", ".env"

# Linked directories - directories that will be symlinked from shared folder
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor/bundle", "storage"

# Keep 5 releases
set :keep_releases, 5

# Puma settings
set :puma_threads, [ 4, 16 ]
set :puma_workers, 2
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma_access.log"
set :puma_error_log, "#{release_path}/log/puma_error.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true
