require 'pty'

module Wooget
  module Util
    def self.author
      `git config user.name || getent passwd $(id -un) | cut -d : -f 5 | cut -d , -f 1`.chomp
    end

    def self.is_a_wooget_package_dir path
      contents = Dir[File.join(path,"*")]
      contents.map! {|c| File.basename(c) }
      contents.include?("paket.dependencies") and contents.include?("RELEASE_NOTES.md")
    end

    def self.is_a_unity_project_dir path
      contents = Dir[File.join(path,"*")]
      contents.map! {|c| File.basename(c) }
      contents.include?("Assets") and contents.include?("ProjectSettings")
    end

    def self.run_cmd cmd, path=Dir.pwd
      Wooget.log.debug "Running `#{cmd}`"

      cmd_output = []

      Dir.chdir(path) do
        begin
          PTY.spawn(cmd) do |stdout, stdin, pid|
            begin
              stdout.each do |line|
                cmd_output << line.uncolorize
                yield line if block_given?
              end
            rescue Errno::EIO
              #This means the process has finished giving output
            ensure
              Process.wait(pid)
            end
          end
        rescue PTY::ChildExited => e
          #Child process exited

        end
      end

      exit_status = $?.exitstatus
      [cmd_output, exit_status]
    end

    def self.file_contains? filename, string
      File.foreach(filename).grep(/#{Regexp.escape(string)}/).any?
    end

    def self.build
      sln = `find . -name *.sln`.chomp
      abort "Can't find sln file for building test artifacts" unless sln.length > 4

      build_log, exitstatus = run_cmd "xbuild #{sln} /p:Configuration=Release"
      abort "Build Failure: #{build_log}" unless exitstatus == 0
    end
  end
end

class String
  REGEXP_PATTERN = /\033\[([0-9]+);([0-9]+);([0-9]+)m(.+?)\033\[0m|([^\033]+)/m

  #get rid of goddamn ansi control codes
  def uncolorize
    result = self.scan(REGEXP_PATTERN).inject("") do |str, match|
      str << (match[3] || match[4])
    end

    #more ansi control codes that the above doesn't pickup
    result.gsub(/\[(?:[A-Z0-9]{1,2}[nmKM]?)|\[(?:\?.*[=<>])|(?:;\d+[nmKM]?)/, '')
  end
end