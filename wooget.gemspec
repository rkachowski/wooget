# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/wooget/version"

Gem::Specification.new do |gem|
  gem.name          = "wooga_wooget"
  gem.version       = Wooget::VERSION
  gem.summary       = "A cli to control all unity/paket package management tasks"
  gem.description   = "Update, install, fetch, list, create, release, prerelease, validate and push paket/unity packages."
  gem.authors       = ["Donald Hutchison"]
  gem.email         = ["donald.hutchison@wooga.net"]
  gem.homepage      = "https://github.com/wooga/wooget"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^pkg/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.0"
end
