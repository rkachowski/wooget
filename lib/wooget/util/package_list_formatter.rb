module Wooget
  class PackageListFormatter
    def self.format_list package_hash, format, show_binary=false

      package_hash.each do |_, packages|
        packages.each do |package|
          package.is_binary = (package.package_id =~ /Binary/ or packages.any? { |p| p.package_id == package.package_id + ".Source" })
          package.has_binary = packages.any? do |p|
            (p.package_id != package.package_id and p.package_id == package.package_id.chomp(".Source"))\
            or p.package_id == package.package_id + ".Binary"
          end
        end
      end

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
  end
end
