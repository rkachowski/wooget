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
      auth = "#{Wooget.credentials[:username]}:#{Wooget.credentials[:password]}"

      reason = Util.run_cmd "nugetkey=#{auth} mono #{path} install"
      unless $?.exitstatus == 0
        abort "Paket install failed:\n #{reason}"
      end

      reason = Util.run_cmd "mono #{unity3d_path} install"
      unless $?.exitstatus == 0
        abort "Paket.Unity3d install failed:\n #{reason}"
      end
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
