require 'pty'
require 'yaml'
require 'resolv'
require 'date'

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

      def initialize(manifest, args) # rubocop:disable Metrics/AbcSize
        @context = args
        load_from_config_file
        add_manifest_to_context(manifest)
        labels_to_array
        env_to_array
        cmd_to_array
        expose_to_array
        entrypoint_to_array
        determine_os
        determine_paths
        determine_if_using_puppetfile
        determine_if_using_hiera
        determine_environment_vars
        determine_hostname
        determine_master_host_and_port
        determine_if_master_is_ip
        validate_context
      end

      def dockerfile
        PuppetX::Puppetlabs::Dockerfile.new(@context)
      end

      def build
        begin
          PTY.spawn(build_command) do |stdout, stdin, pid|
            begin
              stdout.each { |line| print line }
            rescue Errno::EIO # rubocop:disable Lint/HandleExceptions
            end
          end
        rescue PTY::ChildExited => e
          raise BuildError, e.message
        end
      end

      private

      def validate_context
        unless @context[:master]
          raise InvalidContextError, "specified file #{@context[:manifest]} does not exist" unless File.file?(@context[:manifest])
        end
        raise InvalidContextError, 'You must provide an image name, either on the command line or in the metadata file' unless @context[:image_name]
      end

      def add_manifest_to_context(manifest)
        @context[:manifest] = manifest
      end

      def find_metadata_file(file)
        if file.nil?
          false
        elsif File.file?(file)
          file
        elsif @context[:config_directory] && File.file?("#{@context[:config_directory]}/#{file}")
          "#{@context[:config_directory]}/#{file}"
        else
          false
        end
      end

      def determine_master_host_and_port
        if @context[:master]
          parts = @context[:master].split(':')
          if parts.length == 2
            @context[:master_port] = parts[1]
            @context[:master_host] = parts[0]
          else
            @context[:master_host] = @context[:master]
          end
        end
      end

      def determine_if_master_is_ip
        @context[:master_is_ip] = @context[:master_host] =~ Resolv::IPv4::Regex ? true : false
      end

      def host_config
        hostname = @context[:image_name].to_s.split('/').pop
        host_config = find_metadata_file("#{hostname}.yaml")
        host_metadata = {}
        if @context[:image_name] && host_config
          begin
            host_metadata = YAML.load_file(host_config).deep_symbolize_keys
          rescue Psych::SyntaxError
            raise InvalidContextError, "the metadata file #{host_config} does not appear to be valid YAML"
          end
        end
        host_metadata
      end

      def load_from_config_file
        default_config = find_metadata_file(@context[:config_file])
        if @context[:config_file] && default_config
          begin
            metadata = YAML.load_file(default_config).deep_symbolize_keys
          rescue Psych::SyntaxError
            raise InvalidContextError, "the metadata file #{default_config} does not appear to be valid YAML"
          end
          @context = metadata.merge(host_config).merge(@context) if metadata.is_a?(Hash)
        end
      end

      def labels_to_array
        value_to_array(:labels)
      end

      def env_to_array
        value_to_array(:env)
      end

      def expose_to_array
        value_to_array(:expose)
      end

      def cmd_to_array
        value_to_array(:cmd)
      end

      def entrypoint_to_array
        value_to_array(:entrypoint)
      end

      def value_to_array(value)
        @context[value] = @context[value].to_s.split(',') if (@context[value].is_a?(String) || @context[value].is_a?(Fixnum))
      end

      def determine_if_using_puppetfile
        if exists_and_is_file(:puppetfile)
          @context[:use_puppetfile] = true
        end
      end

      def determine_if_using_hiera
        if exists_and_is_file(:hiera_config) && exists_and_is_directory(:hiera_data)
          @context[:use_hiera] = true
        end
      end

      def determine_os
        if @context[:from]
          @context[:os], @context[:os_version] = @context[:from].split(':') unless @context[:os]
        end
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

      def determine_environment_vars # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
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
                           else
                             '4.5.2'
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
        @context[:env].map { |pair| pair.split('=') }.each do |name, value|
          @context[:environment][name] = value
        end unless @context[:env].nil?
      end

      def determine_hostname
        @context[:hostname] = @context[:image_name].split('/').pop if @context[:image_name]
      end

      def build_args
        [
          'cgroup-parent',
          'cpu-period',
          'cpu-quota',
          'cpu-shares',
          'cpuset-cpus',
          'cpuset-mems',
          'isolation',
          'memory-limit',
          'memory-swap',
          'shm-size',
          'ulimit',
          'disable-content-trust',
          'force-rm',
          'no-cache',
          'pull',
          'quiet',
        ].reject { |arg| @context[arg.to_sym].nil? }
      end

      def string_args
        build_args.collect do |arg|
          @context[arg.to_sym] == true ? "--#{arg}" : "--#{arg}=#{@context[arg.to_sym]}"
        end.join(' ')
      end


      def build_command
        dockerfile_path = dockerfile.save.path
        autosign_string = @context[:autosign_token].nil? ? '' : "--build-arg AUTOSIGN_TOKEN=#{@context[:autosign_token]}"
        if @context[:rocker]
          "rocker build #{autosign_string} #{string_args} -f #{dockerfile_path} ."
        else
          "docker build #{autosign_string} #{string_args} -t #{@context[:image_name]} -f #{dockerfile_path} ."
        end
      end

      def exists_and_is_file(value)
        @context[value] && File.file?(@context[value])
      end

      def exists_and_is_directory(value)
        @context[value] && File.directory?(@context[value])
      end
    end
  end
end
