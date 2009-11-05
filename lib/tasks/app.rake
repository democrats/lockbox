# Make certain that the 'net-ssh' get is installed
# And that you have an ssh key for deploy@firefly.dnc.org

require 'rubygems'
require 'net/ssh'

module FoundingFather
  def self.update
    name  = Rails.root.to_s.split("/").last
    print "Repo name: (#{name}) "
    input = $stdin.gets.sub("\n", "")

    unless input.blank?
      name = input.gsub(" ", "-").sub(/([a-z])([A-Z])/, '\1_\2').downcase

      if input != name
        puts "Converted to #{name.sub(".git", "")}"
      end
    end

    base_dir = "/dnc/git/"
    app_dir  = "#{base_dir}#{name}.git"

    Net::SSH.start("firefly.dnc.org", "deploy") do |ssh|
      print "Making #{app_dir}..."
      if ssh.exec!("mkdir #{app_dir}")
        puts "\nssh://firefly.dnc.org#{app_dir} already exists."
      else
        print "done\n"
        git = ssh.exec!("git init #{app_dir} --bare")
        puts git
        if git =~ /Initialized empty Git repository in/
          print "Configuring repo..."
          ssh.exec!("echo '\tsharedRepository = group' >> #{app_dir}/config")
          ssh.exec!("chmod -R g+w #{app_dir}")
          puts "done"
          @success = true
        end
      end
    end
    
    if @success
      print "Linking new remote..."
      `git remote rm origin`
      `git remote add origin ssh://firefly.dnc.org/#{app_dir}`
      `git config branch.master.remote origin`
      `git config branch.master.merge refs/heads/master`
      `git push origin master`
      puts "done"
      puts "Remote Git Repo Setup Complete"
    else
      puts "Remote Git Repo Setup Failed!"
    end

  end
end

namespace :app do
  desc "Configure your new app."
  task :update do
    FoundingFather.update
  end
end