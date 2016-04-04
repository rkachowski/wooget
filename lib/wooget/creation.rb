require 'fileutils'

module Wooget
  #
  #Essential project files for packaging
  #
  class Project < Thor::Group
    attr_reader :options
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), "template", "files")
    end

    def create package_name, options={}
      @options = {}.merge(options)
      @options[:author] ||= Util.author
      @options[:repo] ||= "wdk-unity-universe"
      @options[:source_folder] = package_name

      empty_directory package_name
      create_file File.join(package_name, "paket.lock")
      template("gitignore.erb", File.join(package_name, ".gitignore"))
      template("paket.template.erb", File.join(package_name, "paket.template"))
      template("paket.dependencies.erb", File.join(package_name, "paket.dependencies"))
      template("RELEASE_NOTES.md.erb", File.join(package_name, "RELEASE_NOTES.md"))
      template("README.md.erb", File.join(package_name, "README.md"))
      template("metafile.cs.erb", File.join(package_name,"src", package_name + "_meta.cs"))

      unless options[:no_visualstudio]
        temp = Wooget::Templates::VisualStudio.new()
        destination = File.expand_path("./#{package_name}")

        vs_options = {:destination => destination, :name => package_name, :src =>{}}
        vs_options[:tests] = {} unless options[:no_tests]
        temp.create_project(vs_options)
      end
    end
  end
end
