module Wooget
  module Templates
    def self.paket_template options={}
%(
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
dependencies
)
    end
  end
end