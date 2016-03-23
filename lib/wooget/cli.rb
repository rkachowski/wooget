require 'thor'
require 'fileutils'
require 'json'

module Wooget
  class CLI < Thor
    include Thor::Actions

    desc "create PACKAGE_NAME", "create a new package"
    option :author, desc: "name to use for author field of nupkg"
    def create package_name
      Wooget.create package_name, options
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

      Wooget.credentials = JSON.parse(File.read(config_location), symbolize_names: true)
      Wooget.log.debug "Acting as #{Wooget.credentials[:username]}"
    end
  end
end