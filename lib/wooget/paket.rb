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

    def self.pack options
      cmd = "mono #{path} pack output #{options[:output]} version #{options[:version]} releaseNotes '#{options[:release_notes]}' templatefile #{options[:template]} --verbose"
      Wooget.log.debug "Running #{cmd}"

      system cmd
    end

    def self.push options
      cmd = "nugetkey=#{options[:auth]} mono #{path} push url #{options[:url]} file #{options[:package]} --verbose"
      Wooget.log.debug "Running #{cmd}"

      system cmd
    end

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
