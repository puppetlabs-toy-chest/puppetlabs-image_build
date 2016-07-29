require 'erb'
require 'ostruct'

module PuppetX
  module Puppetlabs
    class Dockerfile < OpenStruct
      def render(template)
        ERB.new(template).result(binding)
      end
    end
  end
end
