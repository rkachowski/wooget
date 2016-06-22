require_relative "wooget/version"
require_relative "wooget/cli"
require_relative "wooget/releasing"
require_relative "wooget/project"
require_relative "wooget/paket"
require_relative "wooget/util/misc"
require_relative "wooget/template/visual_studio"
require_relative "wooget/template/unity"
require_relative "wooget/util/build_error"



# Gem.find_files("wooget/**/*.rb").each { |path| require path }

require 'logger'

module Wooget
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::Severity::ERROR
  @@log.formatter = proc do |severity, datetime, progname, msg|
    msg = msg + "\n" unless msg.end_with? "\n"
    msg.start_with?("[quiet]") ? "#{msg.sub("[quiet]","")}" :  "[#{severity} #{datetime}] : #{msg}"
  end

  @@credentials = {username: "", password: ""}
  @@repos = {:default => "legacy"}

  def self.log
    @@log
  end

  def self.log= log
    @@log = log
  end

  def self.credentials
    @@credentials
  end

  def self.no_status_log msg
    @@log.debug "[quiet]"+msg.uncolorize
  end

  def self.repos
    @@repos
  end

  #default repositiory to use
  def self.repo
    @@repos[:default]
  end
end

