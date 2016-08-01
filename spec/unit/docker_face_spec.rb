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
    rocker: false,
    hiera_config: 'hiera.yaml',
    hiera_data: 'hieradata',
    puppetfile: 'Puppetfile',
    config_file: 'metadata.yaml',
  }.each do |option, value|
    it "has sane defaults for #{option}" do
      expect(subject.get_option(option).default).to eq(value)
    end
  end

  [:dockerfile, :build].each do |subcommand|
    describe "##{subcommand}" do
      it { is_expected.to respond_to subcommand }
      it { is_expected.to be_action subcommand }

      it 'should fail if not passed a manifest' do
        expect { subject.send(subcommand) }.to raise_exception(ArgumentError, /wrong number of arguments/)
      end

      it 'should fail if passed non existent manifest' do
        expect { subject.send(subcommand, 'not-a-real-file') }.to raise_exception(RuntimeError, /does not exist/)
      end
    end
  end

  describe "#build specific options" do
    let(:manifest) { Tempfile.new('manifest.pp') }
    it 'should catch issues with the underlying build' do
      expect_any_instance_of(PuppetX::Puppetlabs::DockerImageBuilder).to receive(:build).and_raise(PuppetX::Puppetlabs::BuildError)
      expect { subject.build(manifest.path, {image_name: 'sample'}) }.to raise_exception(RuntimeError, /the build process was interupted/)
    end

    it 'should run with the minimum options' do
      expect_any_instance_of(PuppetX::Puppetlabs::DockerImageBuilder).to receive(:build)
      expect { subject.build(manifest.path, {image_name: 'sample'}) }.not_to raise_error
    end
  end

  describe "#dockerfile specific options" do
    let(:manifest) { Tempfile.new('manifest.pp') }
    it 'should run with the minimum options' do
      expect_any_instance_of(PuppetX::Puppetlabs::Dockerfile).to receive(:render)
      expect { subject.dockerfile(manifest.path, {image_name: 'sample'}) }.not_to raise_error
    end
  end
end
