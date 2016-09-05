require 'spec_helper'
require 'puppet_x/puppetlabs/acifile'

describe PuppetX::Puppetlabs::Acifile do
  context '#render' do
    it 'should return a string' do
      expect(subject.render).to be_a(String)
    end
  end

  context '#save' do
    it 'should return a file handle' do
      expect(subject.save).to be_a_kind_of(Tempfile)
    end
  end
end
