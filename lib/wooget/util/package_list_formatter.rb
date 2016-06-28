module Wooget
  class PackageListFormatter
    def self.format_list package_hash, format, show_binary=false

      process_binary_packages package_hash

      case format
        when "shell", :shell
          output = ""
          package_hash.each do |repo, packages|
            output << "### #{repo.upcase}\n"
            packages.each do |package|
              next if package.is_binary and not show_binary

              output << "  #{package.package_id} #{"(B)" if package.has_binary and not show_binary} - #{package.version} \n"
            end
            output << "\n"
          end
          output << "- (B) : binary variant available"
          output
        when "json", :json

          unless show_binary
            package_hash.each do |_,packages|
              packages.delete_if {|p| p.is_binary}
            end
          end
          package_hash.to_json
      end
    end

    def self.format_package package_hash, format, package_id=false
      process_binary_packages package_hash

      package = nil
      package_hash.each do |_, packages|
        package = packages.find {|p| p.package_id == package_id}
        break if package
      end

      return "Package '#{package_id}' not found in repos - #{package_hash.keys.join(",")}" unless package

      case format
        when "shell", :shell
          output = ""
          output << "### #{package.package_id}\n"
          %i(version authors created last_updated summary description project_url release_notes
              is_latest_version url has_binary dependencies download_count tags).each do |prop|
            output << "## #{prop.capitalize}\n"
            output << "  " +package.send(prop).to_s + "\n"

          end
          output
        when "json", :json
          package.to_json
      end
    end

    #
    # discern between source and binary packages
    def self.process_binary_packages(package_hash)
      package_hash.each do |_, packages|
        packages.each do |package|
          package.is_binary = (package.package_id =~ /Binary/ or packages.any? { |p| p.package_id == package.package_id + ".Source" })
          package.has_binary = packages.any? do |p|
            (p.package_id != package.package_id and p.package_id == package.package_id.chomp(".Source"))\
            or p.package_id == package.package_id + ".Binary"
          end
        end
      end
    end


  end
end
