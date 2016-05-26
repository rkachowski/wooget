module Wooget
  class Paket
    def self.execute args
      cmd = "mono #{path} #{args}"
      Wooget.log.debug "Running #{cmd}"

      exec cmd
    end

    def self.unity3d_execute args
      cmd = "mono #{unity3d_path} #{args}"
      Wooget.log.debug "Running #{cmd}"

      exec cmd
    end

    def self.install options={}
      paket_commands paket: "install", paket_unity3d: "install", force: options[:force]
    end

    def self.update options={}
      paket_commands paket: "update", paket_unity3d: "install", force: options[:force]
    end

    def self.env_vars
      "USERNAME=#{Wooget.credentials[:username]} PASSWORD=#{Wooget.credentials[:password]}"
    end

    def self.paket_commands options={}
      cmd = "#{env_vars} mono #{path} #{options[:paket]} #{"--force" if options[:force]}"
      reason, exitstatus = Util.run_cmd(cmd) { |log| Wooget.no_status_log log}
      unless exitstatus == 0
        abort "Paket install failed:\n #{reason}"
      end

      if Util.is_a_unity_project_dir(Dir.pwd)
        #TODO: generate unity3d references if applicable

        cmd = "#{env_vars} mono #{unity3d_path} #{options[:paket_unity3d]}"
        reason, exitstatus = Util.run_cmd(cmd) { |log| Wooget.no_status_log log}
        unless exitstatus == 0
          abort "Paket.Unity3d install failed:\n #{reason}"
        end
      end
    end

    def self.installed? project_path, package
      abort "Not a valid paket dir - #{project_path}" unless Util.is_a_unity_project_dir(project_path) or Util.is_a_wooget_package_dir(project_path)

      lock_file = File.join(project_path, "paket.lock")
      return false unless File.exists? lock_file

      File.open(lock_file).read.lines.any? {|l| l =~ /\s*#{package}\s+/ }
    end

    def self.should_generate_unity3d_references
      #if the file doesnt exist, or it does exist but contains "[!automanage!]" then we can rewrite it
      !File.exists?("paket.unity3d.references") or (File.readlines("paket.dependencies").grep(/\[!automanage!\]/).count > 0)
    end

    def self.pack options
      pack_cmd = "#{env_vars} mono #{path} pack output #{options[:output]} version #{options[:version]} releaseNotes '#{options[:release_notes]}' templatefile #{options[:template]}"
      Util.run_cmd(pack_cmd) { |log| Wooget.no_status_log log}
    end

    def self.push options
      push_cmd = "#{env_vars} nugetkey=#{options[:auth]} mono #{path} push url #{options[:url]} file #{options[:package]}"
      Util.run_cmd(push_cmd)  { |log| Wooget.no_status_log log}
     end

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
