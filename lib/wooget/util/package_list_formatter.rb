module Wooget
  class PackageListFormatter
    def self.format_list package_hash, format, show_binary=false

      package_hash.values.each {|list| Package.process_binary_packages(list)}

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
      package_hash.values.each {|list| Package.process_binary_packages(list)}

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
  end
end
