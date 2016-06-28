module Wooget
  class PackageListFormatter
    def self.format package_hash, format
      case format
        when "shell", :shell
          output = ""
          package_hash.each do |repo, packages|
            output << "### #{repo.upcase}\n"
            packages.each do |package|
              output << "  #{package.package_id} - #{package.version}\n"
            end
            output << "\n"
          end
          output
        when "json", :json
          package_hash.to_json
      end
    end
  end
end
