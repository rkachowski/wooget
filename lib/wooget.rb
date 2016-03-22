require_relative "wooget/version"
require_relative "wooget/cli"
require_relative "wooget/releasing"
require_relative "wooget/creation"
require_relative "wooget/util/misc"
require_relative "wooget/template/paket"

# Gem.find_files("wooget/**/*.rb").each { |path| require path }

require 'logger'

module Wooget
  @@log = Logger.new(STDOUT)
  def self.log
    @@log
  end
end

