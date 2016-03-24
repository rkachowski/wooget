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
        @options[:src][:guid] ||= `uuidgen`.chomp if @options[:src]

        template("assemblyinfo.erb", "src/#{options[:name]}/Properties/AssemblyInfo.cs")
        template("sln.erb", "src/#{options[:name]}/#{options[:name]}.sln")
        template("csproj.erb", "src/#{options[:name]}/#{options[:name]}.csproj")
      end
    end
  end
end
