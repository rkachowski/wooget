# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/wooget/version"

Gem::Specification.new do |gem|
  gem.name          = "wooga_wooget"
  gem.version       = Wooget::VERSION
  gem.summary       = "A cli to control all unity/paket package management tasks at wooga"
  gem.description   = "Update, install, fetch, list, create, release, prerelease, validate and push wooga's paket/unity packages."
  gem.authors       = ["Donald Hutchison"]
  gem.email         = ["donald.hutchison@wooga.net"]
  gem.homepage      = "https://github.com/wooga/wooget"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^[pkg|scrap]/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|tests|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "thor", "~> 0.19"
  gem.add_runtime_dependency "curb", "~> 0.8"
  gem.add_runtime_dependency "nokogiri", "~> 1.6.8"
  gem.add_runtime_dependency "activesupport-json_encoder"

  gem.add_development_dependency "pry-byebug", "3.1.0"
  gem.add_development_dependency "rake", "10.5.0"


  gem.metadata['allowed_push_host'] = 'http://gem.sdk.wooga.com'

  gem.required_ruby_version = "~> 2.0"
  gem.post_install_message = Wooget::POST_INSTALL
end
