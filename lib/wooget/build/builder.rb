module Wooget
  module Build
    class Builder < Thor
      def setup build_info

        update_metadata build_info.version
      end

      def perform_build build_info
        setup build_info

        build_result = create_packages(build_info)
        return if build_result == :fail

        built_packages = build_info.package_names.map { |p| File.join(options[:output_dir], p) }

        #dirty hack to prevent unit test versions being pushed
        if build_info.version == "919.919.919"
          Wooget.log.warn "Test packages detected! aborting push"
          return build_info.package_names
        end

        post_build build_info, built_packages
      end

      def post_build build_info, built_packages
        if options[:push]
          built_packages.each do |p|
            if options[:confirm]
              next unless yes?("Release #{p} to #{Wooget.repo}?")
            end

            auth = "#{Wooget.credentials[:username]}:#{Wooget.credentials[:password]}"

            Paket.push auth, Wooget.repo, p
          end
        end

        build_info.package_names
      end

      private

      def create_packages(build_info)
        #if we find a csproj.paket.template file then we need to build a binary release

        Util.build if needs_dll_build(build_info)

        update_metadata build_info.version

        build_info.template_files.each do |t|
          pack_options = {
              output: options[:output_dir],
              version: build_info.version,
              template: t,
              release_notes: build_info.release_notes.shellescape,
              path: build_info.project_root
          }

          stdout, status = Paket.pack pack_options
          unless status == 0
            Wooget.log.error "Pack error: #{stdout.join}"
            return :fail
          end
        end

        nil
      end

      def needs_dll_build(build_info)
        #we have a csproj template file
        return true if build_info.template_files.any? { |t| t.match("csproj.paket.template") }

        #we have different template files that specify both "<PackageName>.Source" and "<PackageName>" ids (legacy)
        source_pkgs = build_info.package_ids.select { |p| p.end_with? ".Source" }
        legacy_dll_pkgs = source_pkgs.map { |p| p.chomp(".Source") }
        return true if build_info.package_ids.any? { |p| legacy_dll_pkgs.include? p }

        false
      end

      def update_metadata new_version
        meta_files = Dir.glob(File.join(options[:path], "**/*_meta.cs"))

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
    class PrereleaseBuilder < Builder

      def setup build_info
        self.options = Thor::CoreExt::HashWithIndifferentAccess.new(options)
        options[:stage] = "Prerelease"

        fail_msg = check_prerelease_preconditions build_info
        abort "Prerelease fail - '#{fail_msg}'" if fail_msg

        set_prerelease_dependencies build_info

        super
      end

      def check_prerelease_preconditions build_info
        return "#{options[:path]} doesn't appear to be a valid package dir" unless Util.is_a_wooget_package_dir options[:path]
        return "Not a prerelease version - \"#{build_info.version}\" found in RELEASE_NOTES.md" unless build_info.version =~ /prerelease/
      end

      def set_prerelease_dependencies build_info
        paket_dependencies = []
        File.open(File.join(options[:path], "paket.dependencies")).each do |line|
          if line.match(/^\s*nuget\s+([\w\.]+)\s*$/)
            paket_dependencies << line.chomp + " prerelease\n"
          else
            paket_dependencies << line
          end
        end

        Wooget.log.debug "Writing out #{paket_dependencies.join} to paket.dependencies"

        File.open(File.join(options[:path], "paket.dependencies"), "w") { |f| f << paket_dependencies.join }

        #add prerelease to the dependencies section of paket.template files
        build_info.template_files.each do |template|
          paket_template = []
          dependencies_section = false

          File.open(File.join(options[:path], template)).each do |line|

            if dependencies_section
              #if this line is not indented we have left the dependencies section
              unless line.match /^\s+/
                dependencies_section = false
                paket_template << line
                next
              end

              #otherwise we append prerelease version tests (unless it's there already)
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

          Wooget.log.debug "Writing out #{paket_template.join} to #{template}"

          File.open(File.join(options[:path], template), "w") { |f| f << paket_template.join }
        end
      end
    end

    class ReleaseBuilder < Builder
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

      def check_release_preconditions
        return "#{Dir.pwd} doesn't appear to be a valid package dir" unless valid_package_dir

        version, prerelease_tag = get_version_from_release_notes
        return "Not a full release - #{version}-#{prerelease_tag}" unless prerelease_tag.empty?
      end
    end
  end
end
