require 'fileutils'

module Wooget
  class Releaser < Thor::Group

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
    def publish options={}
      if options[:preconditions]
        fail_msg = options[:preconditions].call
        abort "#{options[:stage]} error: #{fail_msg}" if fail_msg
      end
      options[:prebuild].call if options[:prebuild]

      clean

      #build package
      package_options = get_package_details
      version = package_options[:version]
      package_name = File.basename(Dir.getwd)+"."+version

      #if we find a csproj.paket.template file then we need to build a binary release
      `find . -name "*csproj.paket.template"`
      needs_dll_build = $?.exitstatus == 0

      Util.build if needs_dll_build

      update_metadata version

      package_options[:templates].each do |t|
        Paket.pack package_options.merge(template: t)
        abort "#{options[:stage]} error: paket pack fail" unless $?.exitstatus == 0
      end

      push(options, package_name)

      package_name
    end

    def push(options, package_name)
      unless options[:push]
        puts "Skipping push - built #{package_name} successfully" unless options[:quiet]
        return
      end

      push_options = get_push_options

      push_options[:packages].each do |package|
        if options[:confirm]
          if yes?("Release #{package} to #{Wooget.repo}?")
            Paket.push push_options.merge(package: package)
            abort "#{options[:stage]} error: paket push fail" unless $?.exitstatus == 0
          else
            abort "Cancelled remote push"
          end
        else
          Paket.push push_options.merge(package: package)
          abort "#{options[:stage]} error: paket push fail" unless $?.exitstatus == 0
        end
      end
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

    private


    def get_package_details

      version, prerelease = get_version_from_release_notes
      version = version+"-"+prerelease unless prerelease.empty?

      {
          :output => "bin",
          :templates => `find . -name "*paket.template"`.split,
          :version => version,
          :release_notes => get_latest_release_notes
      }
    end

    def get_push_options
      {
          :auth => "#{Wooget.credentials[:username]}:#{Wooget.credentials[:password]}",
          :url => Wooget.repo,
          :packages => Dir['bin/*.nupkg']
      }
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
      File.open("RELEASE_NOTES.md").each do |line|
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
end