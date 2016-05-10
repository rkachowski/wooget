require 'thor'
require 'fileutils'
require 'json'
module Wooget
  class CLI < Thor
    include Thor::Actions
    class_option :verbose, :desc => "Spit out tons of logging info", :aliases => "-v", :type => :boolean
    add_runtime_options!

    def initialize *args
      super

      Wooget.log.level = Logger::Severity::DEBUG if self.options[:verbose]
      Wooget.repos[:default] = self.options[:repo] if self.options[:repo]
    end

    desc "create PACKAGE_NAME", "create a new package"
    option :visual_studio, desc: "Should visual studio files (.csproj .sln) be generated?", type: :boolean, default: true
    option :tests, desc: "Should test project be generated?", type: :boolean, default: true
    option :author, desc: "name to use for author field of nupkg"

    def create package_name
      proj = Project.new
      proj.create package_name, options
    end

    option :repo, desc: "Which repo to use"
    option :push, desc: "Should built package be pushed to repo", default: true, type: :boolean
    option :confirm, desc: "Ask for confirmation before pushing", default: true, type: :boolean
    desc "release", "release package in current dir"

    def release
      package_release_checks
      releaser = Releaser.new
      version = releaser.release options
      p "#{version} released successfully to #{Wooget.repo}"
    end

    option :repo, desc: "Which repo to use"
    option :push, desc: "Should built package be pushed to repo", default: true, type: :boolean
    option :confirm, desc: "Ask for confirmation before pushing", default: true, type: :boolean

    desc "prerelease", "prerelease package in current dir"

    def prerelease
      package_release_checks

      releaser = Releaser.new
      version = releaser.prerelease options
      p "#{version} released successfully to #{Wooget.repo}"
    end

    desc "test", "run tests on package in current dir"

    def test
      Util.run_tests
    end

    desc "paket ARGS", "call bundled version of paket and pass args"

    def paket *args
      Wooget::Paket.execute(args.join(" "))
    end

    desc "paket_unity3d ARGS", "call bundled version of paket.unity3d and pass args"

    def paket_unity3d *args
      Wooget::Paket.unity3d_execute(args.join(" "))
    end

    option :force, desc: "Forces the download and reinstallation of all packages.", aliases: "-f", type: :boolean, default: false
    desc "install", "install packages into this unity project"
    def install(package=nil)
      load_config
      
      if Util.is_a_unity_project_dir(Dir.pwd) or Util.is_a_wooget_package_dir(Dir.pwd)
        if package and Util.is_a_unity_project_dir(Dir.pwd)
          Wooget::Unity.new.install package
        end

        Paket.install options
      else
        abort "Unity project not found in current directory"
      end
      p "Installed!"
    end

    option :force, desc: "Forces the download and reinstallation of all packages.", aliases: "-f", type: :boolean, default: false
    desc "update", "update packages into this unity project"
    def update(package=nil)
      load_config

      if Util.is_a_unity_project_dir(Dir.pwd) or Util.is_a_wooget_package_dir(Dir.pwd)
        Paket.update options
      else
        abort "Unity project not found in current directory"
      end
      p "Updated!"
    end

    desc "bootstrap", "setup environment / project for wooget usage"

    def bootstrap
      assert_dependencies
      p "Dependencies OK"
      load_config
      p "Config OK"

      if Util.is_a_unity_project_dir Dir.pwd
        p "Unity project detected - Checking setup"
        Wooget::Unity.new.bootstrap
      end
    end

    private
    def load_config
      config_location = File.expand_path(File.join("~", ".wooget"))
      unless File.exists? config_location
        Wooget.log.info "Creating default config at #{config_location}"

        default_config = File.expand_path(File.join(File.dirname(__FILE__), "template", "wooget_conf.json"))
        FileUtils.cp(default_config, config_location)
      end

      config = JSON.parse(File.read(config_location), symbolize_names: true)

      Wooget.credentials.merge! config[:credentials]
      Wooget.repos.merge! config[:repos]

      if config[:repos][:default]
        Wooget.repos[:default] = config[:repos][:default]
      end

      #set default repo to whatever was passed on commandline (if anything)
      if options[:repo]
        overridden_repo = Wooget.repos[options[:repo]] || Wooget.repos[options[:repo].to_sym]
        abort "Repo '#{options[:repo]}' not found in conf - options are #{Wooget.repos.keys.join(", ")}" unless overridden_repo

        Wooget.repos[:default] = overridden_repo
      end

      Wooget.log.debug "Acting as #{Wooget.credentials[:username]}"
      Wooget.log.debug "Repo is #{Wooget.repo}"
    end

    def assert_package_dir
      abort "#{Dir.pwd} doesn't appear to be a wooget package dir" unless Util.is_a_wooget_package_dir Dir.pwd
    end

    def assert_dependencies
      %w( mono ).each do |dep|
        `which #{dep}`
        abort "Couldn't find #{dep} - please install!" unless $?.exitstatus == 0
      end
    end

    def package_release_checks
      assert_package_dir
      load_config
    end

    def p msg
      say msg unless options[:quiet]
    end
  end
end
