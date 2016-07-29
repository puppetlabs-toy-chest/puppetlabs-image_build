require 'spec_helper'
require 'puppet_x/puppetlabs/dockerfile'

describe PuppetX::Puppetlabs::Dockerfile do
  before(:all) do
    @dockerfile = PuppetX::Puppetlabs::Dockerfile.new
  end

  context '#render' do
    it 'should return a string' do
      expect(@dockerfile.render).to be_a(String)
    end
  end

  context '#save' do
    it 'should return a file handle' do
      expect(@dockerfile.save).to be_a_kind_of(Tempfile)
    end
  end
end
