require 'puppet_x/puppetlabs/imagebuilder'
require 'puppet_x/puppetlabs/imagebuilder_face'

PuppetX::Puppetlabs::ImageBuilder::Face.define(:aci, '0.1.0') do
  summary 'Build Aci images and build scripts using Puppet code'

  action(:build) do
    summary 'Build an ACI image using Puppet'
    arguments '[<manifest>]'
    default

    option '--autosign-token STRING' do
      summary 'An authentication token used for autosigning master-built images'
    end

    when_invoked do |*options|
      args = options.pop
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::AciBuilder.new(manifest, args)
        builder.build
      rescue PuppetX::Puppetlabs::BuildError => e
        raise "An error occured and the build process was interupted: #{e.message}"
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        raise e.message
      end
    end
  end

  action(:script) do
    summary 'Output a shell script for building an ACI with Puppet'
    arguments '[<manifest>]'
    when_invoked do |*options|
      args = options.pop
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::AciBuilder.new(manifest, args)
        builder.build_file.render
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        raise e.message
      end
    end
  end
end
