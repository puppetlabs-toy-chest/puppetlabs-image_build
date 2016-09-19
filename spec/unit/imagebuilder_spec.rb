require 'spec_helper'
require 'puppet_x/puppetlabs/imagebuilder'

describe PuppetX::Puppetlabs::ImageBuilder do
  let(:from) { 'debian:8' }
  let(:image_name) { 'puppet/sample' }
  let(:manifest) { Tempfile.new('manifest.pp') }
  let(:builder) { PuppetX::Puppetlabs::ImageBuilder.new(manifest.path, args) }
  let(:context) { builder.context }

  it_behaves_like 'an image builder'
end
