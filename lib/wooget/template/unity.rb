module Wooget
  class Unity < Thor
    attr_accessor :options
    include Thor::Actions

    class_option :path, desc: "Path to unity project root", default: Dir.pwd

    def self.source_root
      File.join(File.dirname(__FILE__), "files")
    end

    desc "bootstrap", "Add required files to unity project for wooget usage"

    def bootstrap

      dependencies_path = File.join(options[:path], "paket.dependencies")
      if File.exists?(dependencies_path)
        set_wooga_sources dependencies_path
      else
        template("unity_paket.dependencies.erb", File.join(options[:path], "paket.dependencies"))
      end

      required_files = %w(paket.lock paket.unity3d.references).select { |f| not File.exists?(File.join(options[:path], f)) }
      required_files.each { |f| create_file File.join(options[:path], f) }
    end


    #todo: move things below into paket.rb and convert paket.rb to be thor task

    desc "install PACKAGE_ID", "Install specific package into unity project"

    def install package
      unless Util.file_contains? File.join(options[:path], "paket.dependencies"), "nuget #{package}"

        package.split(",").each do |pkg|
          append_to_file File.join(options[:path], "paket.dependencies"), "\nnuget #{pkg}"
        end
      end

      generate_references
    end

    desc "generate_references", "Generate the paket.unity3d.references file from paket.dependency contents"

    def generate_references
      unless Paket.should_generate_unity3d_references? options[:path]
        Wooget.log.debug "automanage tag not found - skipping `paket.unity3d.references` generation"
        return
      end

      to_install = File.open(File.join(options[:path], "paket.dependencies")).readlines.select { |l| l =~ /^\s*nuget \w+/ }
      to_install.map! { |d| d.match(/nuget (\S+)/)[1] }

      File.open(File.join(options[:path], "paket.unity3d.references"), "w") do |f|
        to_install.each { |dep| f.puts(dep) }
      end
    end

    no_commands do
      def set_wooga_sources dependencies_path
        lines = File.open(dependencies_path).readlines
        lines.delete_if {|line| line =~ /wooga\.artifactoryonline\.com\/wooga/}

        wooga_sources = ['source https://wooga.artifactoryonline.com/wooga/api/nuget/nuget-private username: "%USERNAME%" password: "%PASSWORD%"',
        'source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-main username: "%USERNAME%" password: "%PASSWORD%"',
        'source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-universe username: "%USERNAME%" password: "%PASSWORD%"'].map {|l| l + "\n"}

        lines.insert(1, wooga_sources)
        File.open(dependencies_path,"w") {|f| f << lines.join}
      end
    end
  end
end
