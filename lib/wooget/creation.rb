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
        "RELEASE_NOTES.md" => Wooget::Templates.release_notes
    }

    package_files.each do |filename, content|
      File.open(File.join(package_name,filename), "w") { |f| f << content }
    end

    Dir.mkdir(File.join(package_name,"src"))
  end
end
