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

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
