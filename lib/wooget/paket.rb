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

    def self.unity_install
      env_vars = "USERNAME=#{Wooget.credentials[:username]} PASSWORD=#{Wooget.credentials[:password]}"
      reason = Util.run_cmd "#{env_vars} mono #{path} install"
      unless $?.exitstatus == 0
        abort "Paket install failed:\n #{reason}"
      end

=begin
      if should_generate_unity3d_references
        FileUtils.rm("paket.unity3d.references") if File.exists?("paket.unity3d.references")

        #generate unity3d references file from dependencies
      end
=end
      reason = Util.run_cmd "#{env_vars} mono #{unity3d_path} install"
      unless $?.exitstatus == 0
        abort "Paket.Unity3d install failed:\n #{reason}"
      end
    end

    def self.should_generate_unity3d_references
      #if the file doesnt exist, or it does exist but contains "autogenerated by wooget" then we can rewrite it
      !File.exists?("paket.unity3d.references") or (File.readlines("paket.dependencies").grep(/unity\.3d\.references automanaged/).count > 0)
    end

    def self.pack options
      Util.run_cmd "mono #{path} pack output #{options[:output]} version #{options[:version]} releaseNotes '#{options[:release_notes]}' templatefile #{options[:template]}"
    end

    def self.push options
      Util.run_cmd "nugetkey=#{options[:auth]} mono #{path} push url #{options[:url]} file #{options[:package]}"
     end

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
