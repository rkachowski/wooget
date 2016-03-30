module Wooget
  module Templates
    class Paket < Thor::Group
        attr_reader :options
        include Thor::Actions

        def self.source_root
          File.join(File.dirname(__FILE__),"files")
        end

    end
  end
end