# Borrowed from: http://github.com/thoughtbot/suspenders/blob/master/vendor/plugins/limerick_rake/tasks/git.rake

module GitCommands
  class ShellError < RuntimeError; end
 
  @logging = ENV['LOGGING'] != "false"
 
  def self.run cmd, *expected_exitstatuses
    puts "+ #{cmd}" if @logging
    output = `#{cmd} 2>&1`
    puts output.gsub(/^/, "- ") if @logging
    expected_exitstatuses << 0 if expected_exitstatuses.empty?
    raise ShellError.new("ERROR: '#{cmd}' failed with exit status #{$?.exitstatus}") unless
      [expected_exitstatuses].flatten.include?( $?.exitstatus )
    output
  end
  
  def self.ensure_clean_working_directory!
    return if run("git status", 0, 1).match(/working directory clean/)
    raise "Must have clean working directory"
  end
  
  def self.pull_template
    ensure_clean_working_directory!
    run "git pull ssh://firefly.dnc.org/dnc/git/founding_father.git master"
  end
end
 
namespace :git do
  desc "Pull updates from Founding Father, the DNC rails template."
  task :pull do
    GitCommands.pull_template
  end
end