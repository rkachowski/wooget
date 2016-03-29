require 'thor'
require 'fileutils'
require 'json'
require 'pry-byebug'
module Wooget
  class CLI < Thor
    include Thor::Actions
    class_option :verbose, :desc => "Log level", :aliases => "-v", :type => :boolean
    class_option :repo, :desc => "Repository to use", :default => "legacy"
    def initialize *args
      super

      Wooget.log.level = Logger::Severity::DEBUG if self.options[:verbose]
      Wooget.repos[:default] = self.options[:repo] if self.options[:repo]
    end

    desc "create PACKAGE_NAME", "create a new package"
    option :author, desc: "name to use for author field of nupkg"
    def create package_name
      Wooget.create package_name, options
    end

    desc "release", "release package"
    def release
      load_config

      version = Wooget.release
      puts "#{version} released successfully"
    end

    desc "prerelease", "prerelease package"
    def prerelease
      load_config

      version = Wooget.prerelease
      puts "#{version} released successfully"
    end

    desc "paket ARGS", "call bundled version of paket and pass args"
    def paket *args
      Wooget::Paket.execute(args.join(" "))
    end

    desc "paket_unity3d ARGS", "call bundled version of paket.unity3d and pass args"
    def paket_unity3d *args
      Wooget::Paket.unity3d_execute(args.join(" "))
    end

    desc "setup", "setup environment for wooget usage"
    def setup
      assert_dependencies
      puts "Dependencies OK"
      load_config
      puts "Config OK"
    end

    private
    def load_config
      config_location = File.expand_path(File.join("~",".wooget"))
      unless File.exists? config_location
        Wooget.log.info "Creating default config at #{config_location}"

        default_config = File.expand_path(File.join(File.dirname(__FILE__),"template","wooget_conf.json"))
        FileUtils.cp(default_config,config_location)
      end

      config = JSON.parse(File.read(config_location), symbolize_names: true)

      Wooget.credentials.merge! config[:credentials]
      Wooget.repos.merge! config[:repos]

      Wooget.log.debug "Acting as #{Wooget.credentials[:username]}"
    end

    def assert_dependencies
      %w( mono ).each do |dep|
        `which #{dep}`
        raise "Couldn't find #{dep} - please install!" unless $?.exitstatus == 0
      end
    end
  end
end
