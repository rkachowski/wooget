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
      template("gitignore.erb", File.join(package_name, ".gitignore"))
      template("paket.template.erb", File.join(package_name, "paket.template"))
      template("paket.dependencies.erb", File.join(package_name, "paket.dependencies"))
      template("RELEASE_NOTES.md.erb", File.join(package_name, "RELEASE_NOTES.md"))
      template("README.md.erb", File.join(package_name, "README.md"))

      unless options[:no_visualstudio]
        temp = Wooget::Templates::VisualStudio.new()
        destination = File.expand_path("./#{package_name}")

        vs_options = {:destination => destination, :name => package_name, :src =>{}}
        vs_options[:tests] = {} unless options[:no_tests]
        temp.create_project(vs_options)
      end
    end
  end

  def self.create package_name, options={}


    FileUtils.mkdir(package_name)
    template_file = Wooget::Templates.paket_template options

    package_files = {
        "paket.template" => template_file,
        "paket.dependencies" => Wooget::Templates.paket_dependencies,
        "paket.lock" => "",
        ".gitignore" => Wooget::Templates.gitignore,
        "RELEASE_NOTES.md" => Wooget::Templates.release_notes,
        "README.md" => Wooget::Templates.readme(name: package_name, author: options[:author])
    }

    package_files.each do |filename, content|
      File.open(File.join(package_name, filename), "w") { |f| f << content }
    end

    ["src", "tests"].each { |dir| Dir.mkdir(File.join(package_name, dir)) }


  end
end
