module Wooget
  class Paket
    def self.execute args
      exec "mono #{path} #{args}"
    end

    def self.unity3d_execute args
      exec "mono #{unity3d_path} #{args}"
    end

    def self.path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.exe"))
    end

    def self.unity3d_path
      File.expand_path(File.join(__FILE__,"..","third_party","paket.unity3d.exe"))
    end
  end
end
