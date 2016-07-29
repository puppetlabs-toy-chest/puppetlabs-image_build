source 'https://rubygems.org'

group :test do
  gem 'rake'
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4'
  gem 'puppetlabs_spec_helper'
  gem 'metadata-json-lint'
  gem 'rspec'
  gem 'rubocop'
  gem 'simplecov'
  gem 'simplecov-console'
end

group :development do
  gem 'travis'
  gem 'travis-lint'
  gem 'puppet-blacksmith'
  gem 'guard-rake'
  gem 'pry'
  gem 'yard'
end

group :acceptance do
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'beaker-puppet_install_helper'
  gem 'beaker_spec_helper'
end
