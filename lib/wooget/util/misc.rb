module Wooget
  module Util
    def self.author
      `git config user.name || getent passwd $(id -un) | cut -d : -f 5 | cut -d , -f 1`.chomp
    end
  end
end