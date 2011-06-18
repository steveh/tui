require "singleton"
require "yaml"

module Tui
  class Config

    include Singleton

    attr_reader :config

    class << self
      [:host, :username, :password].each do |attribute|
        define_method attribute do
          instance.config[attribute.to_s]
        end
      end
    end

    private

      def initialize
        path = File.expand_path("~/.tui.yml")
        
        @config = File.open(path, "r") do |f|
          YAML.load(f.read)
        end
      end

  end
end
