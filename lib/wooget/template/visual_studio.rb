require 'pry-byebug'

module Wooget
  module Templates
    class VisualStudio  < Thor::Group
      attr_reader :options
      include Thor::Actions

      def self.source_root
        File.join(File.dirname(__FILE__),"visual_studio")
      end

      def create_project options={}
        raise "name not provided" unless options[:name]

        @options = options #needed for erb binding
        @options[:guid] ||= `uuidgen`.chomp

        #src project defaults
        if @options[:src]
          @options[:src][:guid] ||= `uuidgen`.chomp
          @options[:src][:name] ||= options[:name]
          @options[:src][:files]||= []
          @options[:src][:files] << "DummyClass.cs"
        end

        #test project defaults
        if @options[:tests]

        end

        template("assemblyinfo.erb", "#{options[:name]}/src/Properties/AssemblyInfo.cs")
        template("class.erb", "#{options[:name]}/src/DummyClass.cs")
        template("csproj.erb", "#{options[:name]}/src/#{options[:name]}.csproj")
        template("sln.erb", "#{options[:name]}/src/#{options[:name]}.sln")
      end
    end
  end
end
