require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker_spec_helper'

include BeakerSpecHelper

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

ENV['PUPPET_INSTALL_TYPE'] = ENV['PUPPET_INSTALL_TYPE'] || 'agent'
run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  module_name = proj_root.split('-').last
  c.formatter = :documentation
  c.before :suite do
    puppet_module_install(source: proj_root, module_name: module_name)
    hosts.each do |host|
      BeakerSpecHelper.spec_prep(host)
      if fact_on(host, 'osfamily') == 'RedHat'
        on(host, 'sudo yum update -y -q')
        on(host, 'sudo systemctl stop firewalld')
      end
      on host, puppet('module', 'install', 'garethr-docker'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-rkt'), acceptable_exit_codes: [0, 1]
    end
  end
end

def apply_manifest_on_with_exit(host, manifest)
  # acceptable_exit_codes and expect_changes are passed because we want
  # detailed-exit-codes but want to make our own assertions about the
  # responses. Explicit is better than implicit.
  apply_manifest_on(host, manifest, acceptable_exit_codes: (0...256),
                                    expect_changes: true,
                                    debug: true)
end

def apply_manifest_with_exit(manifest)
  # acceptable_exit_codes and expect_changes are passed because we want
  # detailed-exit-codes but want to make our own assertions about the
  # responses. Explicit is better than implicit.
  apply_manifest(manifest, acceptable_exit_codes: (0...256),
                           expect_changes: true,
                           debug: true)
end
