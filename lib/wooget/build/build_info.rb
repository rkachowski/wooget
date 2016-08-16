require 'shellwords'

module Wooget
  module Build
    class BuildInfo
      attr_accessor :template_files, :output_dir, :version, :release_notes, :project_root
      attr_reader :package_ids

      def initialize template_files=[], output_dir=Dir.pwd, version="919.919.919", release_notes="no notes!", project_root=Dir.pwd

        @template_files = template_files
        @output_dir = output_dir
        @version = version
        @release_notes = release_notes

        @invalid_reason = []
        @project_root = project_root
        @package_ids = get_ids
      end

      def package_names
        @package_ids.map { |id| [id, @version, "nupkg"].join "." }
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

      def build_name
        "#{File.basename(@project_root).downcase}-#{version}".shellescape
      end

      def needs_dll_build?
        @template_files.map { |f| Util.file_contains? File.join(project_root, f), "type project" }.any?
      end

      private
      def get_ids
        @template_files.map do |template|
          package_path = template
          package_path = File.join(project_root, template) unless Pathname(template).absolute?

          File.read(package_path).scan(/id (.*)/).flatten.first
        end
      end
    end
  end
end
