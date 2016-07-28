require 'puppet/face'
require 'erb'
require 'ostruct'
require 'pty'
require 'tempfile'


class Dockerfile < OpenStruct
  def render(template)
    ERB.new(template).result(binding)
  end
end

def build_dockerfile(args)
  basepath = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
  template = File.join(basepath, 'templates', '/Dockerfile.erb')
  dockerfile = Dockerfile.new(args)
  dockerfile.render(IO.read(template)).gsub(/\n\n+/, "\n\n");
end

def determine_os(args)
  args[:os], args[:os_version] = args[:image].split(':') unless args[:os]
  args
end

def determine_paths(args)
  args[:puppet_path],
  args[:gem_path],
  args[:r10k_path] = if args[:os] == 'alpine'
                       ['/usr/bin/puppet', 'gem', 'r10k']
                     else
                       ['/opt/puppetlabs/bin/puppet', '/opt/puppetlabs/puppet/bin/gem', '/opt/puppetlabs/puppet/bin/r10k']
                     end
  args
end


def determine_environment_vars(args)
  codename = nil
  wget_version = nil
  puppet_version = nil
  facter_version = nil
  case args[:os]
  when 'ubuntu'
    case args[:os_version]
    when 'latest', 'xenial', nil, /^16\.04/
      codename = 'xenial'
      wget_version = '1.17.1'
    when 'trusty', /^14\.04/
      codename = 'trusty'
      wget_version = '1.15'
    when 'precise', /^12\.04/
      codename = 'precise'
      wget_version = nil
    end
  when 'debian'
    case args[:os_version]
    when 'latest', 'jessie', /^8/
      codename = 'jessie'
      wget_version = nil
    when 'wheezy', /^7/
      codename = 'wheezy'
      wget_version = nil
    end
  when 'centos'
  when 'alpine'
    facter_version = '2.4.6' # latest Ruby version available as a gem
    case args[:puppet_agent_version]
    when '1.5.2'
      puppet_version = '4.5.2'
    when '1.5.1'
      puppet_version = '4.5.1'
    when '1.5.0'
      puppet_version = '4.5.0'
    when '1.4.2'
      puppet_version = '4.4.2'
    when '1.4.1'
      puppet_version = '4.4.1'
    when '1.4.0'
      puppet_version = '4.4.0'
    end
  else
    fail 'puppet docker currently only supports Ubuntu, Debian and Centos base images'
  end
  {
    puppet_agent_version: args[:puppet_agent_version],
    r10k_version: args[:r10k_version],
    codename: codename,
    wget_version: wget_version,
    puppet_version: puppet_version,
    facter_version: facter_version,
  }.reject { |name, value| value.nil? }
end

Puppet::Face.define(:docker, '0.1.0') do
  summary 'Build Docker images and Dockerfiles using Puppet code'

  option '--image STRING' do
    summary 'The base docker image to use for the resulting image'
    default_to { 'ubuntu:16.04' }
  end

  option '--maintainer STRING' do
    summary 'Name and email address for the resulting image'
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
    summary 'Enable advanced options and use Rocker as the build tool'
  end

  option '--disable-inventory' do
    summary 'Enable advanced options and use Rocker as the build tool'
		default_to { false }
  end

  option '--hiera' do
    summary 'Enable use of hiera during build'
		default_to { false }
  end

  option '--[no-]puppetfile' do
    summary 'Enable use of Puppetfile to install dependencies during build'
		default_to { true }
  end

  option '--image-name STRING' do
    summary 'The name of the resulting image'
  end

  action(:build) do
    summary 'Discovery resources (including packages, services, users and groups)'
    arguments '<manifest>'
    when_invoked do |manifest, args|
      fail "#{manifest} does not exist" unless File.file?(manifest)
      fail 'An image name must be provided with --image-name' unless args[:image_name]

      args = determine_os(args)
      args = determine_paths(args)
      args[:manifest] = manifest
			args[:environment] = determine_environment_vars(args)

      file = Tempfile.new('Dockerfile', Dir.pwd)
      file.write(build_dockerfile(args))
      file.close

			build_tool = args[:rocker] ? 'rocker' : 'docker'
      #cmd = "#{build_tool} build -t #{args[:image_name]} -f #{file.path} ."
      cmd = "#{build_tool} build --id #{args[:image_name]} -f #{file.path} ."
			begin
				PTY.spawn(cmd) do |stdout, stdin, pid|
					begin
						stdout.each { |line| print line }
					rescue Errno::EIO
				    fail 'Docker exited during the build'
					end
				end
			rescue PTY::ChildExited
				fail 'Docker exited during the build'
			end
    end
  end

  action(:dockerfile) do
    summary 'Discovery resources (including packages, services, users and groups)'
    arguments '<manifest>'
    when_invoked do |manifest, args|
      fail "#{manifest} does not exist" unless File.file?(manifest)
      args = determine_os(args)
      args = determine_paths(args)
      args[:manifest] = manifest
			args[:environment] = determine_environment_vars(args)
      build_dockerfile(args)
    end
  end
end
