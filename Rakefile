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

ignore_paths = ['contrib/**/*.pp', 'examples/**/*.pp', 'spec/**/*.pp', 'pkg/**/*.pp', 'vendor/**/*']

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = ignore_paths
end

PuppetSyntax.exclude_paths = ignore_paths

RuboCop::RakeTask.new

task test: [
  'check:symlinks',
  'check:dot_underscore',
  'check:git_ignore',
  :lint,
  :syntax,
  :rubocop,
  :metadata_lint,
  :spec
]
