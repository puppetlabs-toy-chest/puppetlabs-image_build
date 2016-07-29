require 'pty'
require 'tempfile'
require 'yaml'

require 'puppet_x/puppetlabs/deep_symbolize_keys'
require 'puppet_x/puppetlabs/dockerfile'

module PuppetX
  module Puppetlabs
    class BuildError < RuntimeError
    end

    class InvalidContextError < RuntimeError
    end

    class DockerImageBuilder
      attr_accessor :context

      def initialize(manifest, args)
        @context = args
        load_from_config_file
        add_manifest_to_context(manifest)
        determine_os
        determine_paths
        determine_if_using_puppetfile
        determine_if_using_hiera
        determine_environment_vars
        validate_context
      end

      def dockerfile
        basepath = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
        template = File.join(basepath, 'templates', '/Dockerfile.erb')
        dockerfile = PuppetX::Puppetlabs::Dockerfile.new(@context)
        dockerfile.render(IO.read(template)).gsub(/\n\n+/, "\n\n");
      end

      def build
        begin
          PTY.spawn(build_command(temporary_dockerfile.path)) do |stdout, stdin, pid|
            begin
              stdout.each { |line| print line }
            rescue Errno::EIO => e
              raise BuildError, e.message
            end
          end
        rescue PTY::ChildExited => e
          raise BuildError, e.message
        end
      end

      private

      def validate_context
        raise InvalidContextError, 'You must provide an image name, either on the command line or in the metadata file' unless @context[:image_name]
      end

      def add_manifest_to_context(manifest)
        raise InvalidContextError, "specified file #{manifest} does not exist" unless File.file?(manifest)
        @context[:manifest] = manifest
      end

      def load_from_config_file
        if File.file?(@context[:config_file])
          begin
            metadata = YAML.load_file(@context[:config_file]).deep_symbolize_keys
          rescue Psych::SyntaxError
            raise InvalidContextError, "the metadata file #{@context[:config_file]} does not appear to be valid YAML"
          end
          @context = metadata.merge(@context)
        end
      end

      def determine_if_using_puppetfile
        if File.file?(@context[:puppetfile])
          @context[:use_puppetfile] = true
        end
      end

      def determine_if_using_hiera
        if File.file?(@context[:hiera_config]) && File.directory?(@context[:hiera_data])
          @context[:use_hiera] = true
        end
      end

      def determine_os
        @context[:os], @context[:os_version] = @context[:from].split(':') unless @context[:os]
      end

      def determine_paths
        @context[:puppet_path],
        @context[:gem_path],
        @context[:r10k_path] = case @context[:os]
                               when 'alpine'
                                 ['/usr/bin/puppet', 'gem', 'r10k']
                               else
                                 ['/opt/puppetlabs/bin/puppet', '/opt/puppetlabs/puppet/bin/gem', '/opt/puppetlabs/puppet/bin/r10k']
                               end
      end

      def determine_environment_vars # rubocop:disable Metrics/AbcSize
        codename = nil
        puppet_version = nil
        facter_version = nil
        case @context[:os]
        when 'ubuntu'
          codename = case @context[:os_version]
                     when 'latest', 'xenial', nil, /^16\.04/
                       'xenial'
                     when 'trusty', /^14\.04/
                       'trusty'
                     when 'precise', /^12\.04/
                       'precise'
                     end
        when 'debian'
          codename = case @context[:os_version]
                     when 'latest', 'jessie', /^8/
                       'jessie'
                     when 'sid'
                       'sid'
                     when 'wheezy', /^7/
                       'wheezy'
                     end
        when 'centos'
        when 'alpine'
          facter_version = '2.4.6' # latest version available as a gem
          puppet_version = case @context[:puppet_agent_version]
                           when '1.5.2'
                             '4.5.2'
                           when '1.5.1'
                             '4.5.1'
                           when '1.5.0'
                             '4.5.0'
                           when '1.4.2'
                             '4.4.2'
                           when '1.4.1'
                             '4.4.1'
                           when '1.4.0'
                             '4.4.0'
                           end
        else
          raise InvalidContextError, 'puppet docker currently only supports Ubuntu, Debian, Alpine and Centos base images'
        end
        @context[:environment] = {
          puppet_agent_version: @context[:puppet_agent_version],
          r10k_version: @context[:r10k_version],
          codename: codename,
          puppet_version: puppet_version,
          facter_version: facter_version,
        }.reject { |name, value| value.nil? }
      end

      def build_command(dockerfile_path)
        if @context[:rocker]
          "rocker build -f #{dockerfile_path} ."
        else
          "docker build -t #{@context[:image_name]} -f #{dockerfile_path} ."
        end
      end

      def temporary_dockerfile
        file = Tempfile.new('Dockerfile', Dir.pwd)
        file.write(dockerfile)
        file.close
        file
      end
    end
  end
end
