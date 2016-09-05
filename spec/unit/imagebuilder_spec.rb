require 'spec_helper'
require 'puppet_x/puppetlabs/imagebuilder'

describe PuppetX::Puppetlabs::ImageBuilder do
  let(:from) { 'debian:8' }
  let(:image_name) { 'puppet/sample' }
  let(:manifest) { Tempfile.new('manifest.pp') }
  let(:builder) { PuppetX::Puppetlabs::ImageBuilder.new(manifest.path, args) }
  let(:context) { builder.context }

  context 'without any arguments' do
    let(:args) { {} }
    it 'should raise an error about missing operating system details' do
      expect { builder.context }.to raise_exception(PuppetX::Puppetlabs::InvalidContextError, /currently only supports/)
    end
  end

  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
      }
    end
    it 'should not raise an error' do
      expect { context }.not_to raise_error
    end
    context 'should produce a context with' do
      it 'the original from value' do
        expect(context).to include(from: args[:from])
      end
      it 'the original image_name value' do
        expect(context).to include(image_name: args[:image_name])
      end
      it 'an operating sytem inferred' do
        expect(context).to include(os: 'debian', os_version: '8')
      end
      it 'paths for Puppet binaries calculated' do
        expect(context).to include(:puppet_path, :gem_path, :r10k_path)
      end
      it 'the OS codename in an environment variable' do
        expect(context[:environment]).to include(codename: 'jessie')
      end
      it 'should expand the entrypoint to an array' do
        expect(context).to include(entrypoint: [])
      end
    end
    it 'should not pass an autosign token build argument' do
      expect(builder.send(:build_command)).not_to include("--build-arg AUTOSIGN_TOKEN=")
    end
    it '#dockerfile should return a Dockerfile object' do
      expect(builder.dockerfile).to be_a(PuppetX::Puppetlabs::Dockerfile)
    end
    it 'should use docker build as the default build command' do
      expect(builder.send(:build_command)).to start_with('docker')
    end
  end

  context 'with a single env value specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        env: 'KEY=value',
      }
    end
    it 'should expand the env to an array' do
      expect(context).to include(env: ['KEY=value'])
    end
    it 'should add the env to the environment used by the image' do
      expect(context[:environment]).to include('KEY' => 'value')
    end
  end

  context 'with a single label specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        labels: 'KEY=value',
      }
    end
    it 'should expand the labels to an array' do
      expect(context).to include(labels: ['KEY=value'])
    end
  end

  context 'with a master specified' do
    let(:master) { 'puppet.example.com' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        master: master,
      }
    end
    it 'should set master host' do
      expect(context).to include(master_host: master)
    end
    it 'should not think master is an IP address' do
      expect(context).to include(master_is_ip: false)
    end
  end

  context 'with a master and port specified' do
    let(:port) { '9090' }
    let(:master) { 'puppet.example.com' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        master: "#{master}:#{port}",
      }
    end
    it 'should set master host' do
      expect(context).to include(master_host: master)
    end
    it 'should set master port' do
      expect(context).to include(master_port: port)
    end
  end

  context 'with a master specified as an IP address' do
    let(:master) { '192.168.0.9' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        master: master,
      }
    end
    it 'should set master host' do
      expect(context).to include(master_host: master)
    end
    it 'should regonise master is an IP address' do
      expect(context).to include(master_is_ip: true)
    end
  end

  context 'with multiple label specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        labels: 'KEY=value,KEY2=value2',
      }
    end
    it 'should expand the labels to an array' do
      expect(context[:labels]).to include('KEY=value', 'KEY2=value2')
    end
  end

  context 'with multiple label specified in a config file' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
labels:
  - KEY=value
  - KEY2=value2
      EOF
      file.close
      file
    end
    let(:args) { { config_file: configfile.path } }
    it 'should expand the labels to an array' do
      expect(context[:labels]).to include('KEY=value', 'KEY2=value2')
    end
  end

  context 'with a single port specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        expose: 80,
      }
    end
    it 'should expand the port to an array' do
      expect(context).to include(expose: ['80'])
    end
  end

  context 'with multiple ports specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        expose: '90,91',
      }
    end
    it 'should expand the labels to an array' do
      expect(context[:expose]).to include('90','91')
    end
  end

  context 'with multiple label specified in a config file' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
expose:
  - 92
  - 93
      EOF
      file.close
      file
    end
    let(:args) { { config_file: configfile.path } }
    it 'should expand the ports to an array' do
      expect(context[:expose]).to include(92,93)
    end
  end

  context 'with a single cmd specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        cmd: 'nginx',
      }
    end
    it 'should expand the cmd to an array' do
      expect(context).to include(cmd: ['nginx'])
    end
  end

  context 'with multiple commands specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        cmd: 'nginx,run',
      }
    end
    it 'should expand the labels to an array' do
      expect(context[:cmd]).to include('nginx', 'run')
    end
  end

  context 'with multiple commands specified in a config file' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
cmd:
  - nginx
  - run
      EOF
      file.close
      file
    end
    let(:args) { { config_file: configfile.path } }
    it 'should expand the commands to an array' do
      expect(context[:cmd]).to include('nginx', 'run')
    end
  end

  context 'with a single entrypoint specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        entrypoint: 'bash',
      }
    end
    it 'should expand the entrypoint to an array' do
      expect(context).to include(entrypoint: ['bash'])
    end
  end

  context 'with multiple entrypoints specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        entrypoint: 'bash,-x',
      }
    end
    it 'should expand the entrypoints to an array' do
      expect(context[:entrypoint]).to include('bash', '-x')
    end
  end

  context 'with multiple entrypoints specified in a config file' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
entrypoint:
  - bash
  - -x
      EOF
      file.close
      file
    end
    let(:args) { { config_file: configfile.path } }
    it 'should expand the entrypoints to an array' do
      expect(context[:entrypoint]).to include('bash', '-x')
    end
  end


  context 'with a Puppetfile provided' do
    let(:puppetfile) { Tempfile.new('Puppetfile') }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        puppetfile: puppetfile.path,
      }
    end
    it 'should not raise an error' do
      expect { context }.not_to raise_error
    end
    it 'should produce a context which enables the puppetfile options' do
      expect(context).to include(use_puppetfile: true)
    end
  end

  context 'with a Puppetfile provided' do
    let(:puppetfile) { Tempfile.new('Puppetfile') }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        puppetfile: puppetfile.path,
      }
    end
    it 'should not raise an error' do
      expect { context }.not_to raise_error
    end
    it 'should produce a context which enables the puppetfile options' do
      expect(context).to include(use_puppetfile: true)
    end
  end

  context 'with a hiera configuration provided' do
    let(:hieraconfig) { Tempfile.new('hiera.yaml') }
    let(:hieradata) { Dir.mktmpdir('hieradata') }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        hiera_config: hieraconfig.path,
        hiera_data: hieradata,
      }
    end
    it 'should not raise an error' do
      expect { context }.not_to raise_error
    end
    it 'should produce a context which enables the hiera options' do
      expect(context).to include(use_hiera: true)
    end
  end

  context 'with an alternative operating system' do
    let(:args) do
      {
        from: 'alpine:3.4',
        image_name: image_name,
      }
    end
    context 'should produce a context with' do
      it 'an operating sytem inferred' do
        expect(context).to include(os: 'alpine', os_version: '3.4')
      end
      it 'paths for Puppet binaries calculated' do
        expect(context).to include(:puppet_path, :gem_path, :r10k_path)
      end
      it 'the facter and puppet version in an environment variable' do
        expect(context[:environment]).to include(:facter_version, :puppet_version)
      end
    end
  end

  context 'with an alternative build tool specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        rocker: true,
      }
    end
    it 'should use rocker build rather than the default' do
      expect(builder.send(:build_command)).to start_with('rocker')
    end
  end

  context 'with an autosign token specified' do
    let(:token) { '12345abcde' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        autosign_token: token,
      }
    end
    it 'should pass the token as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg AUTOSIGN_TOKEN=#{token}")
    end
    context 'using the rocker build tool' do
      let(:args) do
        {
          from: from,
          image_name: image_name,
          autosign_token: token,
          rocker: true,
        }
      end
      it 'should pass the token as a build argument' do
        expect(builder.send(:build_command)).to include("--build-arg AUTOSIGN_TOKEN=#{token}")
      end
    end
  end

  [
    'cgroup-parent',
    'cpu-period',
    'cpu-quota',
    'cpu-shares',
    'cpuset-cpus',
    'cpuset-mems',
    'isolation',
    'memory-limit',
    'memory-swap',
    'shm-size',
    'ulimit'
  ].each do |argument|
    context "when passing --#{argument}" do
      let(:value) { 'abcd' }
      let(:args) do
        Hash[
          :from, from,
          :image_name, image_name,
          argument.to_sym, value,
        ]
      end
      it "should pass #{argument} to the underlying build tool" do
        expect(builder.send(:build_command)).to include("--#{argument}=#{value}")
      end
    end
  end

  [
    'disable-content-trust',
    'force-rm',
    'no-cache',
    'pull',
    'quiet',
  ].each do |argument|
    context "when passing --#{argument}" do
      let(:args) do
        Hash[
          :from, from,
          :image_name, image_name,
          argument.to_sym, true,
        ]
      end
      it "should pass #{argument} to the underlying build tool" do
        expect(builder.send(:build_command)).to include("--#{argument}")
      end
    end
  end

  context 'with a config file used for providing input' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
      EOF
      file.close
      file
    end
    let(:args) { { config_file: configfile.path } }
    it 'should not raise an error' do
      expect { context }.not_to raise_error
    end
    it 'the from value from the config file' do
      expect(context).to include(from: from)
    end
    it 'the image_name value from the config file' do
      expect(context).to include(image_name: image_name)
    end
    context 'do' do
      let(:new_image_name) { 'puppet/different' }
      let(:args) do
        {
          config_file: configfile.path,
          image_name: new_image_name,
        }
      end
      it 'the image_name value to have been overriden' do
        expect(context).to include(image_name: new_image_name)
      end
    end
  end

  context 'with a config file in a directory' do
    let(:configdir) do
      dir = Dir.mktmpdir('metadata')
      file = File.new("#{dir}/metadata.yaml", "w")
      file.write <<-EOF
---
from: #{from}
image_name: #{image_name}
      EOF
      file.close
      dir
    end
    let(:args) do
      {
        config_directory: configdir,
        config_file: 'metadata.yaml'
      }
    end
    it 'should determine the correct from value from the config file' do
      expect(context).to include(from: from)
    end
  end

  context 'with a host override config file in a directory' do
    let(:configdir) do
      dir = Dir.mktmpdir('metadata')
      file = File.new("#{dir}/metadata.yaml", "w")
      file.write <<-EOF
---
from: #{from}
expose: 80
      EOF
      file.close
      file = File.new("#{dir}/sample.yaml", "w")
      file.write <<-EOF
---
expose: 90
      EOF
      file.close
      dir
    end
    let(:args) do
      {
        config_directory: configdir,
        config_file: 'metadata.yaml',
        image_name: image_name,
      }
    end
    it 'should determine the correct from value from the config file' do
      expect(context).to include(from: from)
    end
    it 'should determine the correct port value from the host config file' do
      expect(context).to include(expose: ['90'])
    end
  end

  context 'with an invalid config file used for providing input' do
    let(:configfile) do
      file = Tempfile.new('metadata.yaml')
      file.write <<-EOF
-
invalid
      EOF
      file.close
      file
    end
    let(:args) do
      {
        config_file: configfile.path
      }
    end
    it 'should raise a suitable error' do
      expect { context }.to raise_exception(PuppetX::Puppetlabs::InvalidContextError, /valid YAML/)
    end
  end

  os_codenames = {
    ubuntu: {
      '16.04' => 'xenial',
      '14.04' => 'trusty',
      '12.04' => 'precise',
    },
    debian: {
      '8' => 'jessie',
      '7' => 'wheezy',
    }
  }
  os_codenames.each do |os, hash|
    hash.each do |version, codename|
      context "when inheriting from #{os}:#{version}" do
        let(:args) do
          {
            from: "#{os}:#{version}",
            image_name: image_name,
          }
        end
        it "the codename should be #{codename}" do
          expect(context[:environment]).to include(codename: codename)
        end
      end
    end
  end
end