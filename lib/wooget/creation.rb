require 'fileutils'

module Wooget

  def self.create package_name, options={}
    options[:author] ||= Util.author
    options[:repo] ||= "wdk-unity-universe"
    options[:source_folder] = package_name

    FileUtils.mkdir(package_name)
    template_file = Wooget::Templates.paket_template options

    File.open(File.join(package_name,"paket.template"), "w") do |f|
      f << template_file
    end
  end
end
