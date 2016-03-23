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
   !../#{options[:source_folder]}/tests
   !../**/AssemblyInfo.cs

HERE
    end

    def self.paket_dependencies
<<HERE
//public nuget repo
source https://nuget.org/api/v2

//private wooga repo
source https://wooga.artifactoryonline.com/wooga/api/nuget/nuget-private

//future private wooga repos
source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-main
source https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-universe

nuget NUnit ~> 2
nuget NUnit.Runners ~> 2

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