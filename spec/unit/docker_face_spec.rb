require 'spec_helper'
require 'puppet/face'

describe Puppet::Face[:docker, '0.1.0'] do
  it 'has a default action of build' do
    expect(subject.get_action('build')).to be_default
  end

  it { subject.summary.is_a?(String) }
  [:dockerfile, :build].each do |subcommand|
    describe "##{subcommand}" do
      it { is_expected.to respond_to subcommand }
      it { is_expected.to be_action subcommand }
    end
  end
end
