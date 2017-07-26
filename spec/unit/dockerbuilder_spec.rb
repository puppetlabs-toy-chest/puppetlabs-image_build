require 'spec_helper'
require 'puppet_x/puppetlabs/imagebuilder'

describe PuppetX::Puppetlabs::DockerBuilder do
  let(:from) { 'debian:8' }
  let(:image_name) { 'puppet/sample' }
  let(:manifest) { Tempfile.new('manifest.pp') }
  let(:builder) { PuppetX::Puppetlabs::DockerBuilder.new(manifest.path, args) }
  let(:context) { builder.context }

  it_behaves_like 'an image builder'
  it_behaves_like 'an autosign capable builder'
  it_behaves_like 'a builder capable of utilising an HTTP proxy'
  it_behaves_like 'a builder capable of utilising an APT cache'

  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name
      }
    end

    it '#build_file should return a Dockerfile object' do
      expect(builder.build_file).to be_a(PuppetX::Puppetlabs::Dockerfile)
    end

    it 'should use docker build as the default build command' do
      expect(builder.send(:build_command)).to start_with('docker')
    end
  end

  context 'with an alternative build tool specified' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
        rocker: true
      }
    end
    it 'should use rocker build rather than the default' do
      expect(builder.send(:build_command)).to start_with('rocker')
    end
  end

  context 'with an autosign token for use with rocker specified' do
    let(:token) { '12345abcde' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        autosign_token: token,
        rocker: true
      }
    end
    it 'should pass the token as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg AUTOSIGN_TOKEN=#{token}")
    end
  end

  context 'with an explicit network specified for docker build' do
    let(:network) { 'samplenetwork' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        network: network
      }
    end
    it 'should pass the network as an argument' do
      expect(builder.send(:build_command)).to include("--network #{network}")
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
          argument.tr('-', '_').to_sym, value,
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
    'quiet'
  ].each do |argument|
    context "when passing --#{argument}" do
      let(:args) do
        Hash[
          :from, from,
          :image_name, image_name,
          argument.tr('-', '_').to_sym, true,
        ]
      end
      it "should pass #{argument} to the underlying build tool" do
        expect(builder.send(:build_command)).to include("--#{argument}")
      end
    end
  end
end
