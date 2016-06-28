require 'ostruct'
require 'nokogiri'

module Wooget
  class Nuget < Thor
    def self.from_xml file
      if file.is_a? String and File.exists? file
        file = File.open(file)
      end

      doc = Nokogiri::XML(file)
      doc.remove_namespaces!

      package_xml = doc.css "entry"
      package_xml.map do |px|
        id = px.css("title").text()
        url = px.css("id").text()
        props_xml = px.css("properties")
        properties = props_xml.children.inject({}) do |hsh, node|
          hsh[node.name] = node.text()
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
    attr_reader :require_license_acceptance, :license_url

    def initialize package_id, url, properties
      @package_id = package_id
      @url = url
      @properties = properties || {}

      apply_properties
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
