require 'spec_helper'
require 'puppet_x/puppetlabs/deep_symbolize_keys'

describe 'deep_symbolize_keys' do
  describe Hash do
    it 'should have been monkey patched with deep_symbolize_keys' do
      expect(subject.respond_to?(:deep_symbolize_keys))
    end
    it 'should have symbols for keys after deep_symbolize_keys is called' do
      expect({ 'a' => 1 }.deep_symbolize_keys).to eq(a: 1)
    end
  end

  describe Array do
    it 'should have been monkey patched with deep_symbolize_keys' do
      expect(subject.respond_to?(:deep_symbolize_keys))
    end
    it 'should have symbols for keys after deep_symbolize_keys is called' do
      expect([{ 'a' => 1 }].deep_symbolize_keys).to eq([{ a: 1 }])
    end
  end
end
