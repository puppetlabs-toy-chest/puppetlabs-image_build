require 'puppet_x/puppetlabs/imagebuilder'
require 'puppet_x/puppetlabs/imagebuilder_face'

PuppetX::Puppetlabs::ImageBuilder::Face.define(:docker, '0.1.0') do
  summary 'Build Docker images and Dockerfiles using Puppet code'

  option '--rocker' do
    summary 'Use Rocker as the build tool'
    default_to { false }
  end

  action(:build) do
    summary 'Build a Docker image from Puppet code'
    arguments '[<manifest>]'
    default

    [
      'cgroup-parent STRING',
      'cpu-period INT',
      'cpu-quota   INT',
      'cpu-shares INT',
      'cpuset-cpus STRING',
      'cpuset-mems STRING',
      'disable-content-trust',
      'force-rm',
      'isolation STRING',
      'memory-limit STRING',
      'memory-swap STRING',
      'no-cache',
      'pull',
      'quiet',
      'shm-size STRING',
      'ulimit STRING'
    ].each do |value|
      option "--#{value}" do
        summary "#{value.split.first} argument passed to underlying build tool"
      end
    end

    option '--autosign-token STRING' do
      summary 'An authentication token used for autosigning master-built images'
    end

    when_invoked do |*options|
      args = options.pop
      # no-cache is a boolean option, but Puppet cunningly convert anything begining with no
      # to false. In thise case this option wants passing straight through to Docker build however
      args[:no_cache] = true if args.key? :no_cache
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::DockerBuilder.new(manifest, args)
        builder.build
      rescue PuppetX::Puppetlabs::BuildError => e
        fail "An error occured and the build process was interupted: #{e.message}"
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        fail e.message
      end
    end
  end

  action(:dockerfile) do
    summary 'Generate a Dockerfile which will run the specified Puppet code'
    arguments '[<manifest>]'
    when_invoked do |*options|
      args = options.pop
      manifest = options.empty? ? 'manifests/init.pp' : options.first
      begin
        builder = PuppetX::Puppetlabs::DockerBuilder.new(manifest, args)
        builder.build_file.render
      rescue PuppetX::Puppetlabs::InvalidContextError => e
        fail e.message
      end
    end
  end
end
