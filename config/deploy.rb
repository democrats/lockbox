require 'erb'
APP_NAME = 'lockbox'

set(:real_revision) { source.local.query_revision(revision) { |cmd| with_env("LANG", "C") { run_locally(cmd) } } }
set :application,   "#{APP_NAME}"
set :scm, :git
set :repository,    "ssh://git@gitdev.dnc.org/#{APP_NAME}.git"
set :deploy_to,     "/dnc/app/#{APP_NAME}"
set :shared_path,   "#{deploy_to}/shared"
set :user,          "deploy"
set :runner,        "deploy"
set :keep_releases, 4

task :staging do
  set :rails_env, "staging"
  role :app,  "romulus.dnc.org"
  role :web,  "romulus.dnc.org"
  role :db,   "romulus.dnc.org", :primary => true
  role :cron, "romulus.dnc.org"
end

task :production do
  set :rails_env, "production"
  role :app,      "viper1.dnc.org", "viper2.dnc.org", "viper3.dnc.org"
  role :web,      "viper1.dnc.org", "viper2.dnc.org", "viper3.dnc.org"
  role :db,       "viper1.dnc.org", :primary => true
  role :cron,     "viper1.dnc.org"
end

namespace :config do
  namespace :deploy do
    task :cold do
      # Generate the database.yml file
      puts "Please Enter #{rails_env} Database Credentials"
      print "Database Username: "
      db_username = $stdin.gets.sub('\n','')
      print "Datbase Password: "
      db_password = $stdin.gets.sub('\n','')
      db_config   = ERB.new <<-EOF
      base: &base
        adapter: postgresql
        encoding: utf8
        hostname: localhost
        pool: 5
        timeout: 5000
        username: #{db_username}
        password: #{db_password}
        
      #{rails_env}:
        database: #{application}_#{rails_env}
        <<: *base
      EOF
      put db_config.result, "#{shared_path}/config/database.yml"
      
      # Create a perm copy of lockbox.yml
      %w{lockbox}.each do |file|
        run "cp #{latest_release}/config/#{file}.yml.example #{deploy_to}/shared/config/#{file}.yml"
      end
    end
  end
  
  task :setup do
    %w{database lockbox}.each do |file|
      run "cp #{deploy_to}/shared/config/#{file}.yml #{release_path}/config/#{file}.yml"
    end
  end
end

before "deploy:restart", "config:setup"
before "deploy:migrate", "config:setup"
before "pdf_generator:restart", "files:copy_log4j"
before "pdf_generator:start", "files:copy_log4j"

after  "deploy:setup", "deploy:unroot"
after  "deploy:update_code", "files:compress", "files:copy_cron_jobs"
after  "deploy:restart", "cache:clear", "pdf_generator:restart"

namespace :files do
  task :prepare do
    run "mkdir -p #{deploy_to}/shared/config/"
    
    servers = find_servers(:roles => 'app')
    puts servers.inspect
    if servers.length > 1
      servers.first do |master|
        %w{client lockbox database}.each do |file|
          run "scp #{master}:/dnc/app/#{APP_NAME}/shared/config/#{file}.yml #{deploy_to}/shared/config/#{file}.yml"
        end
      end
    end

    sudo "cp #{current_path}/config/instance_profiles/app/#{rails_env}/nginx.conf /dnc/local/nginx/conf/sites/#{APP_NAME}.conf"
  end
  
  task :copy_cron_jobs, :roles => :cron do
    sudo "cp #{latest_release}/config/instance_profiles/app/#{rails_env}/cron_jobs /etc/cron.d/#{APP_NAME}_cron"
  end
  
  task :copy_log4j do
    run "cp #{latest_release}/config/instance_profiles/app/#{rails_env}/log4j.properties #{latest_release}/pdf_thrift/thrift_java_server/log4j.properties"
  end
  
  task :compress do
    package_files
    compress_packaged_js_files
    compress_packaged_css_files
  end
end

namespace :deploy do
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  task :restart, :roles => :app, :except => { :no_release => true }  do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  task :unroot do
    sudo "chown -R deploy:deploy #{deploy_to}"
  end
  
  desc <<-DESC
    DNC Deploy
    Deploys and starts a 'cold' application. This is useful if you have not \
    deployed your application before, or if your application is (for some \
    other reason) not currently running. It will deploy the code, run any \
    pending migrations, and then instead of invoking 'deploy:restart', it will \
    invoke 'deploy:start' to fire up the application servers.
  DESC
  task :cold do
    update
    files.prepare
    config.deploy.cold
    migrate
    start
  end
end

namespace :nginx do
  desc "reload the nginx.conf file gracefully if changes have been made to it"
  task :reload do
    sudo "pkill -HUP nginx"
  end

  desc "restart nginx"
  task :restart do
    sudo "/etc/init.d/nginx restart"
  end
end

namespace :pdf_generator do
  desc "start server"
  task :start do
    sudo "/etc/init.d/pdfgeneratord start"
  end
  
  desc "stop server"
  task :stop do
    sudo "/etc/init.d/pdfgeneratord stop"
  end
  
  desc "restart server"
  task :restart do
    sudo "/etc/init.d/pdfgeneratord restart"
  end
end

namespace :cache do
  desc "clear memcache if it is set to be the actioncontroller base cache_store"
  task :clear do
    run "#{current_path}/script/runner -e #{rails_env} 'ActionController::Base.cache_store.clear'"
  end
end

def package_files
  run "cd #{latest_release} && rake asset:packager:build_all RAILS_ENV=#{rails_env}"
end

def compress_packages(type, extension)
  dir = "#{latest_release}/public/#{type}"
  files = capture "ls #{dir}"
  files.each do |file_name|
    next if file_name !~ /packaged\.#{extension}$/
    file_path = "#{dir}/#{file_name}"
    run "java -jar /dnc/app/java/yuicompressor-2.4.2.jar --charset utf-8 #{file_path} -o #{file_path}"
  end
end

def compress_packaged_js_files
  compress_packages('javascripts', 'js')
end

def compress_packaged_css_files
  compress_packages('stylesheets', 'css')
end