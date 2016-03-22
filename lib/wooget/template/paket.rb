module Wooget
  module Templates
    def self.paket_template options={}
<<HERE
type file
id #{options[:source_folder]}
owners Wooga
authors #{options[:author]}
projectUrl
    https://github.com/wooga/#{options[:repo]}
requireLicenseAcceptance
    false
copyright
    Copyright #{Time.now.year}
tags
    wdk, unity, wooget
summary
    TODO: fill in summary
description
    TODO: fill in description
files
   ../#{options[:source_folder]}/**/*.cs ==> content/#{options[:source_folder]}
   !../#{options[:source_folder]}/bin
   !../**/AssemblyInfo.cs

HERE
    end

    def self.paket_dependencies
<<HERE
source https://nuget.org/api/v2
source https://wooga.artifactoryonline.com/wooga/api/nuget/nuget-private username: "sdk-universe-user" password: "FMXPSyi2qKsVdWgZUvYhD4"
source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-main username: "sdk-universe-user" password: "FMXPSyi2qKsVdWgZUvYhD4"
source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-universe username: "sdk-universe-user" password: "FMXPSyi2qKsVdWgZUvYhD4"


HERE
    end

    def self.release_notes
<<HERE
### 0.0.0 - #{Time.now.strftime("%d %B %Y")}
* initial release
HERE
    end
  end
end