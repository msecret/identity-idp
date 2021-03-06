#################
# GLOBAL CONFIG
#################
set :application, 'upaya'
# set branch based on env var or ask with the default set to the current local branch
set :branch, ENV['branch'] || ENV['BRANCH'] || ask(:branch, `git branch`.match(/\* (\S+)\s/m)[1])
set :bundle_without, 'deploy development doc test'
set :deploy_via, :remote_cache
set :keep_releases, 5
set :linked_files, %w(config/application.yml
                      config/database.yml
                      keys/saml.key.enc)
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system)
set :rails_env, :production
set :rbenv_ruby, '2.3.1'
set :rbenv_type, :user # or :system, depends on your rbenv setup
set :repo_url, 'https://github.com/18F/identity-idp.git'
set :sidekiq_queue, [:mailers, :sms]
set :ssh_options, forward_agent: false, user: 'ubuntu'
set :whenever_roles, [:app]

#########
# TASKS
#########
namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Install npm packages required for asset compilation with browserify'
  task :browserify do
    on roles(:app), in: :sequence do
      within release_path do
        execute :npm, 'install'
      end
    end
  end

  before 'assets:precompile', :browserify
  after :publishing, :restart
end
