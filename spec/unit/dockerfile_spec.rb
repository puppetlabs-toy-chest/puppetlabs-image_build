require 'spec_helper'
require 'puppet_x/puppetlabs/dockerfile'

describe PuppetX::Puppetlabs::Dockerfile do
  context '#render' do
    it 'should return a string' do
      expect(subject.render).to be_a(String)
    end

    it 'with no arguments should return a blank Dockerfile' do
      expect(subject.render).to be_empty
    end
  end

  context '#save' do
    it 'should return a file handle' do
      expect(subject.save).to be_a_kind_of(Tempfile)
    end
  end
end
