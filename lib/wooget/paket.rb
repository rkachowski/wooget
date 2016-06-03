module Wooget
  class Paket
    @@paket_path = File.expand_path(File.join(__FILE__, "..", "third_party", "paket.exe"))
    @@unity3d_path = File.expand_path(File.join(__FILE__, "..", "third_party", "paket.unity3d.exe"))

    def self.execute args
      cmd = "mono #{ @@paket_path} #{args}"
      Wooget.log.debug "Running #{cmd}"

      exec cmd
    end

    def self.unity3d_execute args
      cmd = "mono #{@@unity3d_path} #{args}"
      Wooget.log.debug "Running #{cmd}"

      exec cmd
    end

    def self.install options={}
      options[:path] ||= Dir.pwd

      commands = ["#{env_vars} mono #{@@paket_path} install #{"--force" if options[:force]}"]
      commands << "#{env_vars} mono #{@@unity3d_path} install" if Util.is_a_unity_project_dir(options[:path])

      commands.each do |cmd|
        reason, exitstatus = Util.run_cmd(cmd, options[:path]) { |log| Wooget.no_status_log log }
        unless exitstatus == 0
          Wooget.log.error "Install failed:\n #{reason}"
          break
        end
      end
    end

    def self.update options={}
      options[:path] ||= Dir.pwd

      commands = ["#{env_vars} mono #{@@paket_path} update #{"--force" if options[:force]}"]
      commands << "#{env_vars} mono #{@@unity3d_path} install" if Util.is_a_unity_project_dir(options[:path])

      commands.each do |cmd|
        reason, exitstatus = Util.run_cmd(cmd, options[:path]) { |log| Wooget.no_status_log log }
        unless exitstatus == 0
          Wooget.log.error "Update failed:\n #{reason}"
          break
        end
      end
    end

    def self.env_vars
      "USERNAME=#{Wooget.credentials[:username]} PASSWORD=#{Wooget.credentials[:password]}"
    end

    def self.installed? project_path, package
      abort "Not a valid paket dir - #{project_path}" unless Util.is_a_unity_project_dir(project_path) or Util.is_a_wooget_package_dir(project_path)

      lock_file = File.join(project_path, "paket.lock")
      return false unless File.exists? lock_file

      File.open(lock_file).read.lines.any? { |l| l =~ /\s*#{package}\s+/ }
    end

    def self.should_generate_unity3d_references? path=Dir.pwd
      #if the references file doesnt exist, or it does exist and
      # it contains the automanage tag then we can rewrite it
      auto_manage_tag = "[!automanage!]"
      !File.exists?(File.join(path, "paket.unity3d.references")) or (Util.file_contains? File.join(path, "paket.dependencies"), auto_manage_tag)
    end

    def self.pack options
      pack_cmd = "#{env_vars} mono #{@@paket_path} pack output #{options[:output]} version #{options[:version]} releaseNotes \"#{options[:release_notes]}\" templatefile #{options[:template]}"
      Util.run_cmd(pack_cmd) { |log| Wooget.no_status_log log }
    end

    def self.push auth, url, package
      push_cmd = "echo #{env_vars} nugetkey=#{auth} mono #{@@paket_path} push url #{url} file #{package}"
      Util.run_cmd(push_cmd) { |log| Wooget.no_status_log log }
    end


  end
end
