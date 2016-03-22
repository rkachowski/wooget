require 'thor'

module Wooget
  class CLI < Thor

    desc "create PACKAGE_NAME", "create a new package"
    option :author, desc: "name to use for author field of nupkg"
    def create package_name
      Wooget.create package_name, options
    end

    desc "paket ARGS", "call bundled version of paket and pass args"
    def paket *args
      Wooget::Paket.execute(args.join(" "))
    end

    desc "paket_unity3d ARGS", "call bundled version of paket.unity3d and pass args"
    def paket_unity3d *args
      Wooget::Paket.unity3d_execute(args.join(" "))
    end
  end
end
