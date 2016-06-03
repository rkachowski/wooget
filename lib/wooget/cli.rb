require 'thor'
require 'fileutils'
require 'json'
module Wooget
  class CLI < Thor
    include Thor::Actions
    class_option :verbose, :desc => "Spit out tons of logging info", :aliases => "-v", :type => :boolean
    class_option :path, desc: "Path to the project you want to install things into", default: Dir.pwd

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

    desc "build", "build the packages in the current dir"
    option :version, desc:"Version number to prepend to release notes", type: :string
    option :output, desc: "Dir to place built packages", type: :string
    def build
      package_release_checks

      Wooget.log.info "Preinstall before build"
      invoke "install", [], quiet:true

      invoke "test"

      #run tests
      #package
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

    desc "test", "run package tests in mono"

    def test
      unless Util.is_a_wooget_package_dir(options[:path]) and Dir.exists?(File.join(options[:path],"tests"))
        Wooget.log.error "Can't find a wooget package dir with tests at #{options[:path]}"
        return
      end

      sln = Dir.glob(File.join(options[:path],"/**/*.sln")).first
      if sln.nil? or sln.empty?
        Wooget.log.error "Can't find sln file for building test artifacts"
        return
      end

      nunit = Dir.glob(File.join(options[:path],"/**/nunit-console.exe")).first
      if nunit.nil? or nunit.empty?
        Wooget.log.error "Can't find nunit-console for running tests"
        return
      end


      Dir.mktmpdir do |tmp_dir|
        p "Building test assembly.."
        stdout, status = Util.run_cmd("xbuild #{sln} /p:OutDir='#{tmp_dir}/'") { |log| Wooget.no_status_log log}
        unless status == 0
          Wooget.log.error "Build Test Failure"
          Wooget.log.error stdout.join "\n"
          return
        end

        Dir[File.join(tmp_dir, "*Tests*.dll")].each do |assembly|
          _, status = Util.run_cmd("mono #{nunit} #{assembly} -nologo") { |log| p log}
          p "Exit Status - #{status}"
        end
      end
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

      if Util.is_a_unity_project_dir(options[:path]) or Util.is_a_wooget_package_dir(options[:path])
        if package and Util.is_a_unity_project_dir(options[:path])
          invoke "wooget:unity:install", [package], options
        end

        Paket.install options
      else
        abort "Project not found at #{options[:path]}"
      end
      p "Installed!"
    end

    option :force, desc: "Forces the download and reinstallation of all packages.", aliases: "-f", type: :boolean, default: false
    desc "update", "update packages into this unity project"
    def update(package=nil)
      load_config

      if Util.is_a_unity_project_dir(options[:path]) or Util.is_a_wooget_package_dir(options[:path])
        Paket.update options
      else
        abort "Project not found at #{options[:path]}"
      end
      p "Updated!"
    end

    desc "bootstrap", "setup environment / project for wooget usage"
    def bootstrap
      assert_dependencies
      p "Dependencies OK"
      load_config
      p "Config OK"

      if Util.is_a_unity_project_dir options[:path]
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
      abort "#{ options[:path]} doesn't appear to be a wooget package dir" unless Util.is_a_wooget_package_dir  options[:path]
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
