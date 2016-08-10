require 'fileutils'
require 'shellwords'

module Wooget
  class Packager < Thor

    class_option :path, desc: "Base path of the package we are working on", default: Dir.pwd
    class_option :output_dir, desc: "Destination for artifacts", default: File.join(Dir.pwd, "bin")

    option :templates, desc: "Template files you want to build", type: :array, required: true
    option :version, desc: "Version to set packages to", type: :string, required: true
    option :release_notes, desc: "Release notes for packages", type: :string, required: true
    option :native, desc: "Invoke native build functionality", type: :boolean, default: true

    desc "build", "build the package and create .nupkg files"

    def build
      clean

      build_info = Build::BuildInfo.new options[:templates], options[:output_dir], options[:version], options[:release_notes], options[:path]
      unless build_info.valid?
        Wooget.log.error "Invalid build options - #{build_info.invalid_reason}"
        return
      end

      builder = Build::Builder.new [], options
      builder.perform_build build_info
    end

    option :push, desc: "push to remote repo", type: :boolean, default: true
    option :confirm, desc: "ask for confirmation before pushing", type: :boolean, default: true
    option :native, desc: "Invoke native build functionality", type: :boolean, default: true

    desc "release", "set release deps, build + push"

    def release
      clean

      build_info = get_build_info_from_template_files
      unless build_info.valid?
        Wooget.log.error "Invalid build options - #{build_info.invalid_reason}"
        return
      end


      builder = Build::ReleaseBuilder.new [], options
      builder.perform_build build_info
    end

    option :push, desc: "push to remote repo", type: :boolean, default: true
    option :confirm, desc: "ask for confirmation before pushing", type: :boolean, default: true
    option :native, desc: "Invoke native build functionality", type: :boolean, default: true
    desc "prerelease", "set prerelease deps, build + push"

    def prerelease
      clean

      build_info = get_build_info_from_template_files
      unless build_info.valid?
        Wooget.log.error "Invalid build options - #{build_info.invalid_reason}"
        return
      end


      builder = Build::PrereleaseBuilder.new [], options
      builder.perform_build build_info
    end

    private

    def clean
      if Dir.exists? File.join(options[:path], "bin")
        Wooget.log.debug "Cleaning bin dir"
        FileUtils.rmtree File.join(options[:path], "bin")
      end

      Dir.mkdir(options[:output_dir]) unless Dir.exists? options[:output_dir]
    end


    def get_build_info_from_template_files

      version, prerelease = get_version_from_release_notes
      version = version+"-"+prerelease unless prerelease.empty?
      templates = Dir.glob(File.join(options[:path], "/**/*paket.template"))

      #make template paths relative to project root
      base = Pathname.new options[:path]
      templates.map! { |t| absolute_template_path = Pathname.new(t); absolute_template_path.relative_path_from(base).to_s }

      Build::BuildInfo.new templates, options[:output_dir], version, get_latest_release_notes, options[:path]
    end

    def get_version_from_release_notes
      regex = /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
      notes = File.open(File.join(options[:path], "RELEASE_NOTES.md")).read
      notes.scan(regex).first
    end

    def get_latest_release_notes
      notes = []
      File.open(File.join(options[:path], "RELEASE_NOTES.md")).each do |line|
        break if line.strip.empty? and notes.length > 0

        #include the line unless it's a version title
        notes << line unless line.match /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
      end

      notes.join
    end
  end
end
