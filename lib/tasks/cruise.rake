APP_NAME = "your app name here"

desc "Cruise Control build task"
task :cruise do
  RAILS_ENV = ENV['RAILS_ENV'] = 'test'
  require 'metric_fu'
  MetricFu::Configuration.run do |config|
    #define which metrics you want to use
    #config.metrics  = [:saikuro, :stats, :flog, :flay, :reek, :rcov]
    config.metrics  = [:stats, :flog, :flay, :rcov]
    config.graphs   = [:flog, :flay, :rcov]
    config.flay     = { :dirs_to_flay => ['app', 'lib']  }
    config.flog     = { :dirs_to_flog => ['app', 'lib']  }
    config.reek     = { :dirs_to_reek => ['app', 'lib']  }
    config.saikuro  = { :output_directory => 'scratch_directory/saikuro',
                        :input_directory => ['app', 'lib'],
                        :cyclo => "",
                        :filter_cyclo => "0",
                        :warn_cyclo => "5",
                        :error_cyclo => "7",
                        :formater => "text"} #this needs to be set to "text"
    config.rcov     = { :test_files => ['test/**/*_test.rb',
                                        'spec/**/*_spec.rb'],
                        :rcov_opts => ["--sort coverage",
                                       "--no-html",
                                       "--text-coverage",
                                       "--no-color",
                                       "--profile",
                                       "--rails",
                                       "--exclude /gems/,/Library/,/rubygems/,spec",
                                       "-Ilib:test"]}
  end
  CruiseControl::invoke_rake_task 'test:load:config'
  CruiseControl::invoke_rake_task 'db:migrate'
  CruiseControl::invoke_rake_task 'db:test:prepare'
  CruiseControl::invoke_rake_task 'test'
  CruiseControl::invoke_rake_task 'metrics:all'
  CruiseControl::invoke_rake_task 'verify_rcov'
end

namespace :test do
  namespace :load do
    desc "loads database.yml and any other relevant configs for the test environment"
    task :config do
      `cp /dnc/app/#{APP_NAME}/shared/config/database.yml /home/deploy/.cruise/projects/#{APP_NAME}/work/config/database.yml`
    end
  end
end

desc "Verify that rcov coverage has not decreased since previous successful build"

def get_coverage(file_location)
  total_coverage = 0
  File.open(file_location).each_line do |line|
    if line =~ /Total Coverage: (\d+\.\d+)%\s/
      total_coverage = $1.to_f
      break
    end
  end
  return total_coverage
end

task :verify_rcov do
  project_root = "/home/deploy/.cruise/projects/#{APP_NAME}"
  html_location = "output/rcov.html"
  out = ENV['CC_BUILD_ARTIFACTS']

  #grab the last rcov level from a successful build (unsuccessful may not have created the file)
  last_build = Dir.new(project_root).entries.select{|f| f =~ /success/}.sort{|a, b| File.mtime(File.join(project_root, a)) <=> File.mtime(File.join(project_root, b))}.last
  threshold = get_coverage(File.join(project_root, last_build, html_location))
  total_coverage = get_coverage(File.join(out, html_location))

  puts "Coverage: #{total_coverage}% (threshold: #{threshold}% from #{last_build})"
  raise "Coverage must be at least #{threshold}% (from #{last_build}) but was #{total_coverage}%" if total_coverage < threshold

end