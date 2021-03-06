require 'ostruct'
require 'oga'
require 'curb'

module Wooget
  class Nuget < Thor
    option :repo_url, desc: "url to the repo", required: true
    desc "packages", "get packages for a repo"

    def packages
      Wooget.log.info "Fetching package list for #{options[:repo_url]} ..."

      url = ""
      if options[:repo_url] == Wooget.repos[:public]
        url = "https://packages.nuget.org/api/v2/Search?searchTerm=%27wooget%27"
      else
        url = options[:repo_url] + '/Search?$orderby=Id&$filter=IsLatestVersion&searchterm='
      end

      c = Curl::Easy.new(url)
      c.username = Wooget.credentials[:username]
      c.password = Wooget.credentials[:password]

      c.perform

      Nuget.from_xml c.body_str
    end

    def self.from_xml file
      if file.is_a? String and File.exists? file
        file = File.open(file)
      end

      doc = Oga.parse_xml(file)

      entries = doc.css "entry"
      entries.map do |e|
        id = e.at_css("title").text()
        url = e.at_css("id").text()
        props_xml = e.at_css("properties").children
        properties = props_xml.inject({}) do |hsh, node|
          hsh[node.name] = node.text() if node.respond_to? :name
          hsh
        end

        Package.new id, url, properties
      end
    end
  end

  class Package
    attr_reader :properties, :url, :package_id

    attr_reader :id, :version, :normalized_version, :authors, :copyright, :created, :dependencies, :description, :download_count
    attr_reader :gallery_details_url, :icon_url, :is_latest_version, :is_absolute_latest_version, :is_prerelease, :language, :last_updated
    attr_reader :published, :package_hash, :package_hash_algorithm, :package_size, :project_url, :report_abuse_url, :release_notes
    attr_reader :require_license_acceptance, :license_url, :summary, :tags

    attr_accessor :has_binary, :is_binary

    def initialize package_id, url, properties
      @package_id = package_id
      @url = url
      @properties = properties || {}

      apply_properties
    end

    #
    # discern between source and binary packages
    def self.process_binary_packages(packages)
      packages.each do |package|
        package.is_binary = (package.package_id =~ /Binary/ or packages.any? { |p| p.package_id == package.package_id + ".Source" })
        package.has_binary = packages.any? do |p|
          (p.package_id != package.package_id and p.package_id == package.package_id.chomp(".Source"))\
            or p.package_id == package.package_id + ".Binary"
        end
      end
    end

    private

    def apply_properties
      @properties.each do |k, v|
        if self.respond_to? "#{k.snake_case}".to_sym

          v = true if v == "true"
          v = false if v == "false"

          instance_variable_set "@#{k.snake_case}".to_sym, v
        end
      end
      @dependencies = @dependencies.split("|") if @dependencies
    end
  end
end
