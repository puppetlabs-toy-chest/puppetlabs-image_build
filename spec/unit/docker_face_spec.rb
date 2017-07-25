require 'tempfile'

require 'spec_helper'
require 'puppet/face'

describe Puppet::Face[:docker, '0.1.0'] do
  it 'has a default action of build' do
    expect(subject.get_action('build')).to be_default
  end

  it 'has a summary for the top level command' do
    expect(subject.summary).to be_a(String)
  end

  {
    inventory: true,
    show_diff: true,
    puppet_debug: false,
    rocker: false,
    label_schema: false,
    hiera_config: 'hiera.yaml',
    hiera_data: 'hieradata',
    puppetfile: 'Puppetfile',
    config_file: 'metadata.yaml'
  }.each do |option, value|
    it "has sane defaults for #{option}" do
      expect(subject.get_option(option).default).to eq(value)
    end
  end

  %i[dockerfile build].each do |subcommand|
    describe "##{subcommand}" do
      it { is_expected.to respond_to subcommand }
      it { is_expected.to be_action subcommand }

      it 'should fail if not passed a manifest because default manifest does not exist' do
        expect(PuppetX::Puppetlabs::DockerBuilder).to receive(:new).with('manifests/init.pp', any_args).and_call_original
        expect { subject.send(subcommand) }.to raise_exception(RuntimeError, %r{does not exist})
      end

      it 'should fail if passed non existent manifest' do
        expect(PuppetX::Puppetlabs::DockerBuilder).to receive(:new).with('not-a-real-file', any_args).and_call_original
        expect { subject.send(subcommand, 'not-a-real-file') }.to raise_exception(RuntimeError, %r{does not exist})
      end

      it 'should have a default value for manifest if not passed explicitly' do
        image_builder = double
        allow(image_builder).to receive(:build)
        allow(image_builder).to receive_message_chain(:build_file, :render)
        expect(PuppetX::Puppetlabs::DockerBuilder).to receive(:new).with('manifests/init.pp', any_args).and_return(image_builder)
        expect { subject.send(subcommand) }.not_to raise_error
      end
    end
  end

  describe '#build specific options' do
    let(:manifest) { Tempfile.new('manifest.pp') }
    it 'should catch issues with the underlying build' do
      expect_any_instance_of(PuppetX::Puppetlabs::DockerBuilder).to receive(:build).and_raise(PuppetX::Puppetlabs::BuildError)
      expect { subject.build(manifest.path, image_name: 'sample') }.to raise_exception(RuntimeError, %r{the build process was interupted})
    end

    it 'should not fail if passed a master even when default manifest does not exist' do
      expect(PuppetX::Puppetlabs::DockerBuilder).to receive(:new).with('manifests/init.pp', any_args).and_call_original
      expect_any_instance_of(PuppetX::Puppetlabs::DockerBuilder).to receive(:build)
      expect { subject.build(master: 'puppet', image_name: 'sample') }.not_to raise_error
    end

    it 'should run with the minimum options' do
      expect_any_instance_of(PuppetX::Puppetlabs::DockerBuilder).to receive(:build)
      expect { subject.build(manifest.path, image_name: 'sample') }.not_to raise_error
    end
  end

  describe '#dockerfile specific options' do
    let(:manifest) { Tempfile.new('manifest.pp') }
    it 'should run with the minimum options' do
      expect_any_instance_of(PuppetX::Puppetlabs::Dockerfile).to receive(:render)
      expect { subject.dockerfile(manifest.path, image_name: 'sample') }.not_to raise_error
    end
    it 'should not fail if passed a master even when default manifest does not exist' do
      expect(PuppetX::Puppetlabs::DockerBuilder).to receive(:new).with('manifests/init.pp', any_args).and_call_original
      expect_any_instance_of(PuppetX::Puppetlabs::Dockerfile).to receive(:render)
      expect { subject.dockerfile(master: 'puppet', image_name: 'sample') }.not_to raise_error
    end
  end
end
