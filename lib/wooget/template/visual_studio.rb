module Wooget
  module Templates
    class VisualStudio  < Thor::Group
      attr_accessor :options
      include Thor::Actions
      add_runtime_options!

      def self.source_root
        File.join(File.dirname(__FILE__),"files")
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

        template("assemblyinfo.erb", "#{options[:name]}/src/#{options[:name]}/Properties/AssemblyInfo.cs")
        template("class.erb", "#{options[:name]}/src/#{options[:name]}/DummyClass.cs")
        template("csproj.erb", "#{options[:name]}/src/#{options[:name]}/#{options[:name]}.csproj")
        template("paket.binary.template.erb", "#{options[:name]}/src/#{options[:name]}/#{options[:name]}.csproj.paket.template")

        if @options[:tests]
          @options[:tests][:guid] ||= `uuidgen`.chomp
          @options[:tests][:files]||= []
          @options[:tests][:name] ||= options[:name]
          @options[:tests][:files] << "DummyTest.cs"

          #referencing src project from test project
          @options[:tests][:projects]||= []
          src_project = {:guid => @options[:src][:guid], :name => @options[:src][:name], :relative_location => "../src/#{options[:name]}/#{options[:name]}.csproj" }
          @options[:tests][:projects] << src_project

          template("test_file.erb", "#{options[:name]}/tests/DummyTest.cs")
          template("tests_csproj.erb", "#{options[:name]}/tests/#{options[:name]}.Tests.csproj")
          template("tests_assemblyinfo.erb", "#{options[:name]}/tests/Properties/AssemblyInfo.cs")
          template("paket.references.erb", "#{options[:name]}/tests/paket.references")
        end

        template("sln.erb", "#{options[:name]}/src/#{options[:name]}.sln")
      end
    end
  end
end
