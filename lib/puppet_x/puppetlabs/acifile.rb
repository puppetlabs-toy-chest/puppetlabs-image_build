require 'erb'
require 'ostruct'
require 'tempfile'

module PuppetX
  module Puppetlabs
    class Acifile < OpenStruct
      attr_accessor :template
      def initialize(hash = nil, &block)
        basepath = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
        @template = File.join(basepath, 'templates', '/build-aci.sh.erb')
        super
      end

      def render
        ERB.new(IO.read(@template)).result(binding).gsub(%r{\n\n+}, "\n\n").strip
      end

      def save
        file = Tempfile.new('build-aci.sh', Dir.pwd)
        file.write(render)
        file.close
        file
      end
    end
  end
end
