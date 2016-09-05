require 'rubygems'
require 'bundler/setup'

require 'rubocop/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

# These gems aren't always present, for instance
# on Travis with --without development

begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

begin
  require 'rubycritic/rake_task'
  RubyCritic::RakeTask.new do |task|
    task.paths   = FileList['lib/**/*.rb']
    task.options = '--format=console --no-browser'
  end
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

RuboCop::RakeTask.new

task test: [
  :rubocop,
  :metadata_lint,
  :spec,
]
