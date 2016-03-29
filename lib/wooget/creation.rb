require 'fileutils'

module Wooget

  def self.create package_name, options={}
    options = {}.merge(options)
    options[:author] ||= Util.author
    options[:repo] ||= "wdk-unity-universe"
    options[:source_folder] = package_name

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
      File.open(File.join(package_name,filename), "w") { |f| f << content }
    end

    ["src","tests"].each {|dir| Dir.mkdir(File.join(package_name,dir)) }

    temp = Wooget::Templates::VisualStudio.new()
    destination = File.expand_path("./#{package_name}")
    temp.create_project({:destination => destination, :name=> package_name, :src =>{}, :tests => {}})
  end
end
