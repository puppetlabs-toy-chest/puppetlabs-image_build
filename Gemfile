source 'https://rubygems.org'

group :test do
  gem 'coveralls', require: false
  gem 'metadata-json-lint'
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4'
  gem 'puppetlabs_spec_helper'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'simplecov-console'
end

group :development do
  gem 'guard-rake'
  gem 'listen', '<3.1'
  gem 'maintainers'
  gem 'pry'
  gem 'puppet-blacksmith'
  gem 'r10k'
  gem 'rubycritic', require: false
  gem 'travis'
  gem 'travis-lint'
  gem 'yard'
end

group :acceptance do
  gem 'beaker', '~> 2.0'
  gem 'beaker-puppet_install_helper'
  gem 'beaker-rspec'
  gem 'beaker_spec_helper'
end
