require 'puppet/face'

require 'puppet_x/puppetlabs/dockerimagebuilder'

Puppet::Face.define(:docker, '0.1.0') do
  summary 'Build Docker images and Dockerfiles using Puppet code'

  option '--from STRING' do
    summary 'The base docker image to use for the resulting image'
    default_to { 'ubuntu:16.04' }
  end

  option '--maintainer STRING' do
    summary 'Name and email address for the maintainer of the resulting image'
  end

  option '--os STRING' do
    summary 'The operating system used by the image if not autodetected'
  end

  option '--os-version STRING' do
    summary 'The version of the operating system used by the image if not autodetected'
  end

  option '--puppet-agent-version STRING' do
    summary 'Version of the Puppet Agent package to install'
    default_to { '1.5.2' }
  end

  option '--r10k-version STRING' do
    summary 'Version of R10k to use for installing modules from Puppetfile'
    default_to { '2.2.2' }
  end

  option '--expose STRING' do
    summary 'A list of ports to be exposed by the resulting image'
  end

  option '--cmd STRING' do
    summary 'The default command to be executed by the resulting image'
  end

  option '--entrypoint STRING' do
    summary 'The default entrypoint for the resulting image'
  end

  option '--labels KEY=VALUE' do
    summary 'A set of labels to be applied to the resulting image'
  end

  option '--rocker' do
    summary 'Use Rocker as the build tool'
		default_to { false }
  end

  option '--[no-]inventory' do
    summary 'Enable or disable the generation of an inventory file at /inventory.json'
		default_to { true }
  end

  option '--hiera-config STRING' do
    summary 'Hiera config file to use'
    default_to { 'hiera.yaml' }
  end

  option '--hiera-data STRING' do
    summary 'Hieradata directory to use'
    default_to { 'hieradata' }
  end

  option '--puppetfile STRING' do
    summary 'Enable use of Puppetfile to install dependencies during build'
		default_to { 'Puppetfile' }
  end

  option '--image-name STRING' do
    summary 'The name of the resulting image'
  end

  option '--config-file STRING' do
    summary 'A configuration file with all the metadata'
    default_to { 'metadata.yaml' }
  end

  action(:build) do
    summary 'Discovery resources (including packages, services, users and groups)'
    arguments '[<manifest>]'
    default
    when_invoked do |*options|
      args = options.pop
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::DockerImageBuilder.new(manifest, args)
        builder.build
      rescue PuppetX::Puppetlabs::BuildError => e
        fail "An error occured and the build process was interupted: #{e.message}"
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        fail e.message
      end
    end
  end

  action(:dockerfile) do
    summary 'Discovery resources (including packages, services, users and groups)'
    arguments '[<manifest>]'
    when_invoked do |*options|
      args = options.pop
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::DockerImageBuilder.new(manifest, args)
        builder.dockerfile.render
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        fail e.message
      end
    end
  end
end
