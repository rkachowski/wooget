require 'thor'
require 'fileutils'
require 'json'
require 'pathname'
require 'activesupport/json_encoder'

module Wooget
  class CLI < Thor
    include Thor::Actions
    class_option :verbose, :desc => "Spit out tons of logging info", :aliases => "-v", :type => :boolean
    class_option :quiet, :desc => "Suppress stdout", :aliases => "-q", :type => :boolean, default: false
    class_option :path, desc: "Path to the project you want to install things into", default: Dir.pwd


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
    option :version, desc:"Version number to prepend to release notes", type: :string, required: true
    option :output, desc: "Dir to place built packages", type: :string, default: File.join(Dir.pwd,"bin")
    option :release_notes, desc: "Release notes to include in the package", type: :string, default: ""
    def build
      package_release_checks

      p "Preinstall before build"
      invoke "install", [], quiet:true, path:options[:path]

      p "Running tests"
      invoke "test", [], path:options[:path]

      #templates refs have to be relative to the working dir / project root for paket.exe
      path = Pathname.new(options[:path])
      templates = Dir.glob(File.join(options[:path],"**/*paket.template"))
      templates.map! { |t| Pathname.new(t).relative_path_from(path).to_s}

      build_options = {
          output_dir: options[:output],
          version:options[:version],
          release_notes: options[:release_notes],
          templates: templates,
          path: options[:path]
      }

      built_packages = invoke "wooget:packager:build", [], build_options

      p "#{built_packages.join " & "} built to #{File.expand_path options[:output]}" if built_packages
    end

    option :repo, desc: "Which repo to use"
    option :push, desc: "Should built package be pushed to repo", default: true, type: :boolean
    option :confirm, desc: "Ask for confirmation before pushing", default: true, type: :boolean
    desc "release", "release package in current dir"

    def release
      package_release_checks
      releaser = Packager.new
      released_packages = releaser.release options
      p "#{released_packages.join " & "} released successfully" if released_packages
    end

    option :repo, desc: "Which repo to use"
    option :push, desc: "Should built package be pushed to repo", default: true, type: :boolean
    option :confirm, desc: "Ask for confirmation before pushing", default: true, type: :boolean

    desc "prerelease", "prerelease package in current dir"

    def prerelease
      package_release_checks

      releaser = Packager.new [], options
      released_packages = releaser.prerelease
      p "#{released_packages.join " & "} prereleased successfully" if released_packages
    end

    desc "test", "run package tests in mono"

    def test
      unless Util.is_a_wooget_package_dir(options[:path]) and Dir.exists?(File.join(options[:path],"tests"))
        Wooget.log.error "Can't find a wooget package dir with tests at #{options[:path]}"
        return
      end

      slns = Dir.glob(File.join(options[:path],"/**/*.sln"))
      sln = slns.select{ |d| not Wooget::Util.is_a_unity_project_dir(File.dirname(d))}.first

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
        stdout, status = Util.run_cmd("xbuild #{File.expand_path(sln)}  /t:Rebuild  /p:RestorePackages='False' /p:Configuration='Release' /p:OutDir='#{tmp_dir}/'") { |log| Wooget.no_status_log log}
        raise BuildError, stdout.join unless status == 0

        Dir[File.join(tmp_dir, "*Tests*.dll")].each do |assembly|
          _, status = Util.run_cmd("mono #{nunit} #{assembly} -nologo -labels -noshadow") { |log| p log}
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
        invoke "wooget:unity:bootstrap", [], options
      end
    end

    option :repos, desc: "Which repos to list", type: :array, default: ["main", "universe","legacy"]
    option :format, desc: "What format to output results", type: :string, enum: ["shell","json"], default: "shell"
    option :show_binary, desc: "Display binary packages in output", type: :boolean, default: false
    desc "list", "list available packages + version"
    def list package_id=nil
      load_config

      packages_by_repo = {}
      packages_by_repo_lock = Mutex.new

      threads = options[:repos].map do |repo|
        Thread.new do
          url = Wooget.repos[repo] || Wooget.repos[repo.to_sym]
          raise RepoError, "Can't find a repository with name '#{repo}' in the configuration" unless url

          nuget = Nuget.new
          packages = nuget.invoke "packages", [], repo_url:url
          packages_by_repo_lock.synchronize { packages_by_repo[repo] = packages}
        end
      end

      threads.each {|t| t.join}

      result = ""

      if package_id
        result = PackageListFormatter.format_package packages_by_repo, options[:format], package_id
      else
        result = PackageListFormatter.format_list packages_by_repo, options[:format], options[:show_binary]
      end

      p result
    end


    no_commands do
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
    end

    private


    def assert_package_dir
      abort "#{ options[:path]} doesn't appear to be a wooget package dir" unless Util.is_a_wooget_package_dir  options[:path]
    end

    def assert_dependencies
      %w( mono ).each do |dep|
        `type #{dep}`
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
