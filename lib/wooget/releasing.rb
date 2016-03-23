require 'pry-byebug'

module Wooget
  def self.prerelease
    fail_msg = check_prerelease_preconditions
    abort "Release error: #{fail_msg}" if fail_msg

    set_prerelease_dependencies

    #check untracked files
    #build.sh setup prerelease
    #paket update
    #paket install
    #build.sh prerelease
  end

  def self.release
    fail_msg = check_release_preconditions
    abort "Release error: #{fail_msg}" if fail_msg

    set_release_dependencies

    #update

    Paket.pack get_build_options
    abort "Release error: paket pack fail" unless $?.exitstatus == 0

    Paket.push get_push_options
    abort "Release error: paket push fail" unless $?.exitstatus == 0
  end

  private

  def self.get_build_options

    version, prerelease = get_version_from_release_notes
    version = version+"-"+prerelease unless prerelease.empty?

    {
        :output => "bin",
        :template => "paket.template",
        :version => version,
        :release_notes => get_latest_release_notes
    }
  end

  def self.get_push_options
    {
        :auth => "#{Wooget.credentials[:username]}:#{Wooget.credentials[:password]}",
        :url => Wooget.credentials[:repo],
        :package => Dir['bin/*.nupkg'].max { |f| File.ctime(f) }
    }
  end

  def self.set_release_dependencies
    #remove prerelease references from dependencies and template
    %w(paket.template paket.dependencies).each do |file|
      release_dependencies = []
      File.open(file).each do |line|
        release_dependencies << line.sub(/\s*[>=]{1}\s*.*(prerelease)|prerelease/,"")
      end

      Wooget.log.debug "Writing out #{release_dependencies.join} to #{file}"

      File.open(file,"w"){|f| f << release_dependencies.join }
    end
  end

  def self.set_prerelease_dependencies
    #add prerelease to dependencies
    paket_dependencies = []
    File.open("paket.dependencies").each do |line|
      if line.match(/^\s*nuget\s+([\w\.]+)\s*$/)
        paket_dependencies << line.chomp + " prerelease\n"
      else
        paket_dependencies << line
      end
    end

    Wooget.log.debug "Writing out #{paket_dependencies.join} to paket.dependencies"

    File.open("paket.dependencies","w"){|f| f << paket_dependencies.join }

    #add prerelease to the dependencies section of paket.template
    paket_template = []
    dependencies_section = false

    File.open("paket.template").each do |line|

      if dependencies_section
        #if this line is not indented we have left the dependencies section
        unless line.match /^\s+/
          dependencies_section = false
          paket_template << line
          next
        end

        #otherwise we append prerelease version spec (unless it's there already)
        unless line.match />= 0.0.0-prerelease/
          paket_template << "#{line.chomp} >= 0.0.0-prerelease\n"
          next
        end
      end

      if !dependencies_section and line.match /^dependencies/
        dependencies_section = true
      end

      paket_template << line
    end

    Wooget.log.debug "Writing out #{paket_template.join} to paket.template"

    File.open("paket.template","w"){|f| f << paket_template.join }
  end

  def self.check_release_preconditions
    return "#{Dir.pwd} doesn't appear to be a valid package dir" unless valid_package_dir

    version, prerelease_tag = get_version_from_release_notes
    return "Not a full release - #{version}-#{prerelease_tag}" unless prerelease_tag.empty?
  end

  def self.check_prerelease_preconditions
    return "#{Dir.pwd} doesn't appear to be a valid package dir" unless valid_package_dir

    version, prerelease_tag = get_version_from_release_notes
    return "Not a prerelease - #{version}" if prerelease_tag.empty?
  end

  def self.get_version_from_release_notes
    regex = /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
    notes = File.open("RELEASE_NOTES.md").read
    notes.scan(regex).first
  end

  def self.get_latest_release_notes
    notes = []
    File.open("RELEASE_NOTES.md").each do |line|
      break if line.empty? and notes.length > 0

      #include the line unless it's a version title
      notes << line unless line.match /#*\s*(\d+\.\d+\.\d+)-?(\w*)/
    end

    notes.join
  end

  def self.valid_package_dir
    dir_files = Dir.glob("*")
    required_files = %w(RELEASE_NOTES.md paket.template paket.dependencies paket.lock)

    required_files.all? { |required_file| dir_files.include? required_file}
  end
end