module Wooget
  module Templates
    class Misc < Thor::Group
      attr_reader :options
      include Thor::Actions

      def self.source_root
        File.join(File.dirname(__FILE__), "files")
      end
    end

    def self.readme options
      <<HERE

HERE
    end

    def self.gitignore
      <<HERE

HERE
    end
  end
end
