require 'spec_helper'
require 'puppet_x/puppetlabs/imagebuilder'

describe PuppetX::Puppetlabs::AciBuilder do
  let(:from) { 'debian:8' }
  let(:image_name) { 'puppet/sample' }
  let(:manifest) { Tempfile.new('manifest.pp') }
  let(:builder) { PuppetX::Puppetlabs::AciBuilder.new(manifest.path, args) }
  let(:context) { builder.context }

  it_behaves_like 'an image builder'

  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name
      }
    end

    it '#build_file should return a Acifile object' do
      expect(builder.build_file).to be_a(PuppetX::Puppetlabs::Acifile)
    end

    it 'should use bash as the default build command' do
      expect(builder.send(:build_command)).to start_with('bash')
    end
  end
end
