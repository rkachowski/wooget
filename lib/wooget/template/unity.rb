module Wooget
  class Unity < Thor
    attr_accessor :options
    include Thor::Actions
    add_runtime_options!

    class_option :path, desc: "Path to unity project root", default: Dir.pwd

    def self.source_root
      File.join(File.dirname(__FILE__),"files")
    end

    desc "bootstrap", "Add required files to unity project for wooget usage"
    def bootstrap
      required_files = %w(paket.lock paket.dependencies paket.unity3d.references)
      missing_files = required_files.select { |f| not File.exists?(File.join(options[:path],f))}
      return unless missing_files.length > 0

      #todo: handle situations where files exist but without required content (source refs in paket.dependencies)

      template("unity_paket.dependencies.erb", File.join(options[:path],"paket.dependencies"))
      create_file File.join(options[:path],"paket.lock")
      create_file File.join(options[:path],"paket.unity3d.references")
    end


    #todo: move things below into paket.rb and convert paket.rb to be thor task

    desc "install PACKAGE_ID", "Install specific package into unity project"
    def install package
      unless Util.file_contains? File.join(options[:path],"paket.dependencies"), "nuget #{package}"

        append_to_file File.join(options[:path],"paket.dependencies"),"\nnuget #{package}"

      end

      generate_references
    end

    desc "generate_references", "Generate the paket.unity3d.references file from paket.dependency contents"
    def generate_references
      unless Paket.should_generate_unity3d_references? options[:path]
        Wooget.log.debug "automanage tag not found - skipping `paket.unity3d.references` generation"
        return
      end

      to_install = File.open(File.join(options[:path],"paket.dependencies")).readlines.select { |l| l =~ /^\s*nuget \w+/ }
      to_install.map! { |d| d.match(/nuget (\S+)/)[1] }

      File.open(File.join(options[:path],"paket.unity3d.references"), "w") do |f|
        to_install.each { |dep| f.puts(dep) }
      end
    end

    # def update package
    #
    # end
  end
end
