require 'fileutils'
require 'pry-byebug'
require 'shellwords'

module Wooget
  class Packager < Thor

    class_option :path, desc: "Base path of the package we are working on", default: Dir.pwd
    class_option :output_dir, desc: "Destination for artifacts", default: File.join(Dir.pwd, "bin")

    option :templates, desc: "Template files you want to build", type: :array, required: true
    option :version, desc: "Version to set packages to", type: :string, required: true
    option :release_notes, desc: "Release notes for packages", type: :string, required: true
    desc "build", "build the package and create .nupkg files"

    def build
      build_info = BuildInfo.new options[:templates], options[:output_dir], options[:version], options[:release_notes]
      unless build_info.valid?
        Wooget.log.error "Invalid build options - #{build_info.invalid_reason}"
        return
      end

      Dir.mkdir(options[:output_dir]) unless Dir.exists? options[:output_dir]

      build_packages build_info
    end

    no_commands do

      #publish in prerelease mode
      def prerelease options={}
        prerelease_options = {
            stage: "Prerelease",
            preconditions: -> { check_prerelease_preconditions },
            prebuild: -> { set_prerelease_dependencies }
        }

        publish options.merge(prerelease_options)
      end

      #publish in release mode
      def release options={}
        release_options = {
            stage: "Release",
            preconditions: -> { check_release_preconditions },
            prebuild: -> { set_release_dependencies }
        }

        publish options.merge(release_options)
      end

      #build and push packages
      def publish args={}
        if args[:preconditions]
          fail_msg = args[:preconditions].call
          abort "#{args[:stage]} error: #{fail_msg}" if fail_msg
        end
        args[:prebuild].call if args[:prebuild]

        clean

        build_info = get_build_info_from_file
        build_result = build_packages(build_info)
        return if build_result == :fail

        built_packages = build_info.package_names.map {|p| File.join(options[:output_dir],p)}
        return build_info.package_names unless args[:push]

        built_packages.each do |p|
          if args[:confirm]
            next unless yes?("Release #{p} to #{Wooget.repo}?")
          end

          auth = "#{Wooget.credentials[:username]}:#{Wooget.credentials[:password]}"

          Paket.push auth, Wooget.repo, p
        end

        build_info.package_names
      end

      def build_packages(build_info)
        #if we find a csproj.paket.template file then we need to build a binary release
        needs_dll_build = build_info.template_files.any? { |t| t.match("csproj.paket.template") }

        Util.build if needs_dll_build

        update_metadata build_info.version

        build_info.template_files.each do |t|
          stdout, status = Paket.pack output: options[:output_dir], version: build_info.version, template: t, release_notes: build_info.release_notes.shellescape
          unless status == 0
            Wooget.log.error "Pack error: #{stdout.join}"
            return :fail
          end
        end

        nil
      end

      def clean
        if Dir.exists? "bin"
          Wooget.log.debug "Cleaning bin dir"
          FileUtils.rmtree "bin"
        end
      end

      # update the client side tracking metadata with the latest version
      def update_metadata new_version
        meta_files = Dir.glob("**/*_meta.cs")

        meta_files.each do |file|
          file_contents = File.open(file).each_line.to_a
          file_contents.map! do |line|
            if line =~ /public static readonly string version/
              "    public static readonly string version = \"#{new_version}\";\n"
            else
              line
            end
          end
          File.open(file, "w") { |f| f << file_contents.join }
        end
      end
    end

    private


    def get_build_info_from_file

      version, prerelease = get_version_from_release_notes
      version = version+"-"+prerelease unless prerelease.empty?
      templates = Dir.glob(File.join(options[:path], "/**/*paket.template"))

      BuildInfo.new templates, options[:output_dir], version, get_latest_release_notes
    end

    #
    # sets release dependencies on paket files and creates release template
    def set_release_dependencies
      #remove prerelease references from dependencies and template
      %w(paket.template paket.dependencies).each do |file|
        release_dependencies = []
        File.open(file).each do |line|
          release_dependencies << line.sub(/\s*[>=]{1}\s*.*(prerelease)|prerelease/, "")
        end

        Wooget.log.debug "Writing out #{release_dependencies.join} to #{file}"

        File.open(file, "w") { |f| f << release_dependencies.join }
      end
    end

    #
    # sets prerelease dependencies on paket files and creates prerelease template
    def set_prerelease_dependencies
      #add prerelease to dependencies
      paket_dependencies = []
      File.open("paket.dependencies").each do |line|
        if line.match(/^\s*nuget\s+([\w\.]+)\s*$/)
          paket_dependencies << line.chomp + " prerelease\n"
        else
          paket_dependencies << line
        end
      end

      Wooget.log.debug "Writing out #{paket_dependencies.join} to paket.dependencies"

      File.open("paket.dependencies", "w") { |f| f << paket_dependencies.join }

      #add prerelease to the dependencies section of paket.template
      paket_template = []
      dependencies_section = false

      File.open("paket.template").each do |line|

        if dependencies_section
          #if this line is not indented we have left the dependencies section
          unless line.match /^\s+/
            dependencies_section = false
            paket_template << line
            next
          end

          #otherwise we append prerelease version spec (unless it's there already)
          unless line.match />= 0.0.0-prerelease/
            paket_template << "#{line.chomp} >= 0.0.0-prerelease\n"
            next
          end
        end

        if !dependencies_section and line.match /^dependencies/
          dependencies_section = true
        end

        paket_template << line
      end

      Wooget.log.debug "Writing out #{paket_template.join} to paket.template"

      File.open("paket.template", "w") { |f| f << paket_template.join }
    end

    def check_release_preconditions
      return "#{Dir.pwd} doesn't appear to be a valid package dir" unless valid_package_dir

      version, prerelease_tag = get_version_from_release_notes
      return "Not a full release - #{version}-#{prerelease_tag}" unless prerelease_tag.empty?
    end

    def check_prerelease_preconditions
      return "#{Dir.pwd} doesn't appear to be a valid package dir" unless valid_package_dir

      version, prerelease_tag = get_version_from_release_notes
      return "Not a prerelease - #{version}" if prerelease_tag.empty?
    end

    def get_version_from_release_notes
      regex = /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
      notes = File.open("RELEASE_NOTES.md").read
      notes.scan(regex).first
    end

    def get_latest_release_notes
      notes = []
      File.open(File.join(options[:path], "RELEASE_NOTES.md")).each do |line|
        break if line.empty? and notes.length > 0

        #include the line unless it's a version title
        notes << line unless line.match /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
      end

      notes.join
    end

    def valid_package_dir
      dir_files = Dir.glob("*")
      required_files = %w(RELEASE_NOTES.md paket.template paket.dependencies paket.lock)

      required_files.all? { |required_file| dir_files.include? required_file }
    end
  end

  class BuildInfo
    attr_accessor :template_files, :output_dir, :version, :release_notes

    def initialize template_files=[], output_dir=Dir.pwd, version="919.919.919", release_notes="no notes!"

      @template_files = template_files
      @output_dir = output_dir
      @version = version
      @release_notes = release_notes

      @invalid_reason = []
    end

    def package_names
      @template_files.map do |template|
        package_id = File.read(template).scan(/id (.*)/).flatten.first
        [package_id, @version, "nupkg"].join "."
      end
    end

    def invalid_reason
      @invalid_reason.join ", "
    end

    def valid?
      valid = true

      unless Util.valid_version_string? @version
        @invalid_reason << "Invalid version string #{@version}"
        valid = false
      end

      unless @template_files.length > 0
        @invalid_reason << "No template files provided"
        valid = false
      end

      valid
    end
  end
end
