module Wooget
  module Util
    def self.author
      `git config user.name || getent passwd $(id -un) | cut -d : -f 5 | cut -d , -f 1`.chomp
    end

    def self.is_a_wooget_package_dir path
      contents = Dir["*"]

      contents.include?("paket.template") and contents.include?("RELEASE_NOTES.md")
    end

    def self.is_a_unity_project_dir path
      contents = Dir["*"]

      contents.include?("Assets") and contents.include?("ProjectSettings")
    end

    def self.run_cmd cmd
      Wooget.log.debug "Running #{cmd}"
      result = `#{cmd}`
      Wooget.log.debug "Output: #{result}"
      result
    end

    def self.run_tests
      assert_package_dir
      sln = `find . -name *.sln`.chomp
      abort "Can't find sln file for building test artifacts" unless sln.length > 4

      nunit = `find . -name nunit-console.exe`.chomp
      abort "Can't find nunit-console for running tests" unless nunit.length > 4

      Dir.mktmpdir do |tmp_dir|
        #build tests
        run_cmd "xbuild #{sln} /p:OutDir='#{tmp_dir}/'"
        raise "Build Test Failure" unless $?.exitstatus == 0

        #run any test assemblies with nunit console
        Dir[File.join(tmp_dir,"*Tests*.dll")].each do |assembly|
          puts run_cmd("mono #{nunit} #{assembly} -nologo")
        end
      end
    end
  end
end