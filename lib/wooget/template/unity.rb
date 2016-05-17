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

    def install package
      unless Util.file_contains? "paket.dependencies", "nuget #{package}"
        `echo '\nnuget #{package}' >> paket.dependencies`
      end

      generate_references
    end

    def update package

    end

    def generate_references
      unless Paket.should_generate_unity3d_references
        Wooget.log.debug "automanage tag not found - skipping `paket.unity3d.references` generation"
        return
      end

      to_install = File.open("paket.dependencies").readlines.select { |l| l =~ /^\s*nuget \w+/ }
      to_install.map! { |d| d.match(/nuget (\S+)/)[1] }

      File.open("paket.unity3d.references", "w") do |f|
        to_install.each { |dep| f.puts(dep) }
      end
    end
  end
end
