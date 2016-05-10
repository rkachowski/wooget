module Wooget
  class Unity < Thor::Group
    attr_accessor :options
    include Thor::Actions
    add_runtime_options!

    def self.source_root
      File.join(File.dirname(__FILE__),"files")
    end

    def bootstrap
      required_files = %w(paket.lock paket.dependencies paket.unity3d.references)
      missing_files = required_files.select { |f| not File.exists?(f)}
      return unless missing_files.length > 0

      #todo: handle situations where files exist but without required content (source refs in paket.dependencies)

      template("unity_paket.dependencies.erb", "paket.dependencies")
      create_file "paket.lock"
      create_file "paket.unity3d.references"
    end
  end
end
