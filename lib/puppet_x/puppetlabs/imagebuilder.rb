require 'pty'
require 'yaml'
require 'resolv'
require 'date'
require 'English'

require 'puppet_x/puppetlabs/deep_symbolize_keys'
require 'puppet_x/puppetlabs/dockerfile'
require 'puppet_x/puppetlabs/acifile'

module PuppetX
  module Puppetlabs
    class BuildError < RuntimeError
    end

    class InvalidContextError < RuntimeError
    end

    class ImageBuilder
      attr_accessor :context

      def initialize(manifest, args)
        @context = args
        load_from_config_file
        add_manifest_to_context(manifest)
        labels_to_array
        add_label_schema_labels
        env_to_array
        cmd_to_array
        expose_to_array
        volume_to_array
        entrypoint_to_array
        determine_os
        determine_paths
        determine_if_using_puppetfile
        determine_if_using_factfile
        determine_if_using_hiera
        determine_environment_vars
        determine_repository_details
        determine_hostname
        determine_master_host_and_port
        determine_if_master_is_ip
        validate_context
      end

      def build
        run(build_command)
      end

      private

      def pty(cmd, &block)
        PTY.spawn(cmd, &block)
        $CHILD_STATUS
      end

      def run(command)
        status = pty(command) do |stdout, _stdin, pid|
          begin
            stdout.each { |line| print line }
          rescue Errno::EIO # rubocop:disable Lint/HandleExceptions
          end
          Process.wait(pid)
        end
        unless status.nil? || status.success?
          raise BuildError, 'The docker build process exited with a non-zero status code'
        end
      rescue PTY::ChildExited => e
        raise BuildError, e.message
      end

      def validate_context
        unless @context[:master]
          raise InvalidContextError, "specified file #{@context[:manifest]} does not exist" unless File.exist?(@context[:manifest])
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
          @context = @context.merge(metadata).merge(host_config) if metadata.is_a?(Hash)
        end
      end

      def labels_to_array
        value_to_array(:labels)
      end

      def add_label_schema_labels
        if @context[:label_schema]
          @context[:labels].insert(
            -1,
            "org.label-schema.build-date=#{Time.now.utc.iso8601}",
            'org.label-schema.schema-version=1.0'
          )
        end
      end

      def env_to_array
        value_to_array(:env)
      end

      def expose_to_array
        value_to_array(:expose)
      end

      def volume_to_array
        value_to_array(:volume)
      end

      def cmd_to_array
        value_to_array(:cmd)
      end

      def entrypoint_to_array
        value_to_array(:entrypoint)
      end

      def value_to_array(value)
        @context[value] = @context[value].to_s.split(',') if @context[value].is_a?(String) || @context[value].is_a?(Integer) || @context[value].nil?
      end

      def determine_if_using_puppetfile
        @context[:use_puppetfile] = true if exists_and_is_file(:puppetfile)
      end

      def determine_if_using_factfile
        @context[:use_factfile] = true if exists_and_is_file(:factfile)
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

      def determine_environment_vars
        codename = nil
        puppet_version = nil
        facter_version = nil
        case @context[:os]
        when 'ubuntu'
          codename = case @context[:os_version]
                     when 'latest', 'xenial', nil, %r{^16\.04}
                       'xenial'
                     when 'trusty', %r{^14\.04}
                       'trusty'
                     when 'precise', %r{^12\.04}
                       'precise'
                     end
        when 'debian'
          codename = case @context[:os_version]
                     when 'latest', 'stable', 'stable-slim', 'stable-backports', 'stretch', 'stretch-slim', 'stretch-backports', %r{^9}
                       'stretch'
                     when 'oldstable', 'oldstable-slim', 'oldstable-backports', 'jessie', 'jessie-slim', 'jessie-backports', %r{^8}
                       'jessie'
                     when 'sid', 'sid-slim'
                       'sid'
                     when 'wheezy', %r{^7}
                       'wheezy'
                     end
        when 'alpine'
          facter_version = '2.4.6' # latest version available as a gem
          puppet_version = case @context[:puppet_agent_version]
                           when '1.8.2'
                             '4.8.1'
                           when '1.8.1'
                             '4.8.1'
                           when '1.8.0'
                             '4.8.0'
                           when '1.7.1'
                             '4.7.0'
                           when '1.7.0'
                             '4.7.0'
                           when '1.6.2'
                             '4.6.2'
                           when '1.6.1'
                             '4.6.1'
                           when '1.6.0'
                             '4.6.0'
                           when '1.5.3'
                             '4.5.3'
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
        when 'centos' # rubocop:disable Lint/EmptyWhen
        else
          raise InvalidContextError, 'puppet docker currently only supports Ubuntu, Debian, Alpine and Centos base images'
        end
        @context[:environment] = {
          puppet_agent_version: @context[:puppet_agent_version],
          r10k_version: @context[:r10k_version],
          codename: codename,
          puppet_version: puppet_version,
          facter_version: facter_version
        }.reject { |_name, value| value.nil? }
        unless @context[:env].nil?
          @context[:env].map { |pair| pair.split('=') }.each do |name, value|
            @context[:environment][name] = value
          end
        end
      end

      def determine_repository_details
        puppet5 = @context[:puppet_agent_version].to_f >= 5 ? true : false
        @context[:package_address], @context[:package_name] = case @context[:os]
                                                              when 'ubuntu', 'debian'
                                                                if puppet5
                                                                  [
                                                                    'https://apt.puppetlabs.com/puppet5-release-"$CODENAME".deb',
                                                                    'puppet5-release-"$CODENAME".deb'
                                                                  ]
                                                                else
                                                                  [
                                                                    'https://apt.puppetlabs.com/puppetlabs-release-pc1-"$CODENAME".deb',
                                                                    'puppetlabs-release-pc1-"$CODENAME".deb'
                                                                  ]
                                                                end
                                                              when 'centos'
                                                                if puppet5
                                                                  "https://yum.puppetlabs.com/puppet5/puppet5-release-el-#{@context[:os_version]}.noarch.rpm"
                                                                else
                                                                  "https://yum.puppetlabs.com/puppetlabs-release-pc1-el-#{@context[:os_version]}.noarch.rpm"
                                                                end
                                                              end
      end

      def determine_hostname
        @context[:hostname] = @context[:image_name].split('/').pop if @context[:image_name]
      end

      def exists_and_is_file(value)
        @context[value] && File.file?(@context[value])
      end

      def exists_and_is_directory(value)
        @context[value] && File.directory?(@context[value])
      end
    end

    class DockerBuilder < ImageBuilder
      def build_file
        PuppetX::Puppetlabs::Dockerfile.new(@context)
      end

      def build_args
        %w[
          cgroup_parent
          cpu_period
          cpu_quota
          cpu_shares
          cpuset_cpus
          cpuset_mems
          isolation
          memory_limit
          memory_swap
          shm_size
          ulimit
          disable_content_trust
          force_rm
          no_cache
          pull
          quiet
        ].reject { |arg| @context[arg.to_sym].nil? }
      end

      def string_args
        build_args.map do |arg|
          with_hyphen = arg.tr('_', '-')
          @context[arg.to_sym] == true ? "--#{with_hyphen}" : "--#{with_hyphen}=#{@context[arg.to_sym]}"
        end.join(' ')
      end

      def autosign_string
        @context[:autosign_token].nil? ? '' : "--build-arg AUTOSIGN_TOKEN=#{@context[:autosign_token]}"
      end

      def http_proxy_string
        @context[:http_proxy].nil? ? '' : "--build-arg http_proxy=#{@context[:http_proxy]}"
      end

      def https_proxy_string
        @context[:https_proxy].nil? ? '' : "--build-arg https_proxy=#{@context[:https_proxy]}"
      end

      def apt_proxy_string
        @context[:apt_proxy].nil? ? '' : "--build-arg APT_PROXY=#{@context[:apt_proxy]}"
      end

      def squash_string
        @context[:squash] ? '--squash' : ''
      end

      def command_build_args
        "#{autosign_string} #{apt_proxy_string} #{http_proxy_string} #{https_proxy_string} #{string_args} #{squash_string}"
      end

      def docker_network
        @context[:network].nil? ? '' : "--network #{@context[:network]}"
      end

      def build_command
        dockerfile_path = build_file.save.path
        if @context[:rocker]
          "rocker build #{command_build_args} -f #{dockerfile_path} ."
        else
          "docker build #{command_build_args} #{docker_network} -t #{@context[:image_name]} -f #{dockerfile_path} ."
        end
      end
    end

    class AciBuilder < ImageBuilder
      def build_file
        PuppetX::Puppetlabs::Acifile.new(@context)
      end

      def build_command
        "bash #{build_file.save.path}"
      end
    end
  end
end
