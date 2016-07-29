require 'spec_helper'
require 'puppet/face'

describe Puppet::Face[:docker, '0.1.0'] do
  it 'has a default action of build' do
    expect(subject.get_action('build')).to be_default
  end

  it 'has a summary for the top level command' do
    subject.summary.is_a?(String)
  end

  {
    disable_inventory: false,
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
    end
  end
end
