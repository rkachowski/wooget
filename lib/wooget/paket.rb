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

    def self.paket_commands commands={}
      reason = Util.run_cmd "#{env_vars} mono #{path} #{commands[:paket]} #{"--force" if commands[:force]}"
      unless $?.exitstatus == 0
        abort "Paket install failed:\n #{reason}"
      end

      if Util.is_a_unity_project_dir(Dir.pwd)
        #TODO: generate unity3d references if applicable

        reason = Util.run_cmd "#{env_vars} mono #{unity3d_path} #{commands[:paket_unity3d]}"
        unless $?.exitstatus == 0
          abort "Paket.Unity3d install failed:\n #{reason}"
        end
      end
    end

    def self.should_generate_unity3d_references
      #if the file doesnt exist, or it does exist but contains "[!automanage!]" then we can rewrite it
      !File.exists?("paket.unity3d.references") or (File.readlines("paket.dependencies").grep(/\[!automanage!\]/).count > 0)
    end

    def self.pack options
      Util.run_cmd "#{env_vars} mono #{path} pack output #{options[:output]} version #{options[:version]} releaseNotes '#{options[:release_notes]}' templatefile #{options[:template]}"
    end

    def self.push options
      Util.run_cmd "#{env_vars} nugetkey=#{options[:auth]} mono #{path} push url #{options[:url]} file #{options[:package]}"
     end

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
