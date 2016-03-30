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
  end
end