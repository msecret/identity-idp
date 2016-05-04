environment ENV['RACK_ENV'] || 'productions'
port        ENV['VCAP_APP_PORT'] || ENV['PORT'] || 3000
rackup      DefaultRackup
threads_count = Integer(ENV['MAX_THREADS'] || 2)
threads threads_count, threads_count
workers Integer(ENV['WEB_CONCURRENCY'] || 1)

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

preload_app!
