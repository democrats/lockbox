namespace :yml do
  desc "Copies all config/*.yml.[hostname] or config/*.yml.example files to config/*.yml"
  task :bootstrap do
    if current_host.length > 0
      Dir["#{RAILS_ROOT}/config/*.yml.#{current_host}"].each do |yml_host|
        copy_to_yml(yml_host) 
      end
    end

    Dir["#{RAILS_ROOT}/config/*.yml.example"].each do |yml_example|
      copy_to_yml(yml_example)
    end
  end
end

def current_host
  @current_host ||= `hostname -s`.chomp.downcase
end

def copy_to_yml(src, overwrite_existing=false)
  dest = File.join(File.dirname(src), File.basename(src, File.extname(src)))
  if overwrite_existing || !File.exist?(dest)
    copy(src, dest)
  end
end
