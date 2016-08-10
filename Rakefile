# # #
# Get gemspec info
require 'octokit'
require 'json'
require 'httpclient'

gemspec_file = Dir['*.gemspec'].first
gemspec = eval File.read(gemspec_file), binding, gemspec_file
info = "#{gemspec.name} | #{gemspec.version} | " \
"#{gemspec.runtime_dependencies.size} dependencies | " \
  "#{gemspec.files.size} files"


# # #
# Gem build and install task

desc info
task :gem do
  %w(pry-byebug binding.pry).each do |dbg|
    files = `ack -ir #{dbg} lib`
    abort "debuggin statements left in! - #{files}" if $?.exitstatus == 0
  end

  puts info + "\n\n"
  print "  "; sh "gem build #{gemspec_file}"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
  puts; sh %{gem install --no-document pkg/#{gemspec.name}-#{gemspec.version}.gem}
end

desc "Build and push to sdk.wooga.com + create github release"
task :release => :gem do
  name = "#{gemspec.name}-#{gemspec.version}.gem"
  access_token = JSON.parse(File.open(File.expand_path("~/.wooget")).read)["credentials"]["github_token"]

  #push to gem server
  puts "pushing to gem.sdk.wooga.com"
  client = HTTPClient.new ""
  resp =  client.post "http://gem.sdk.wooga.com/upload", {'file'=> File.open(File.join("pkg",name))}
  puts "response from gem.sdk.wooga.com #{resp.body}"

  #create github release
  puts "Preparing github release #{name}"
  git_url = `git remote get-url origin`.chomp.chomp ".git"
  url = git_url.split(":").last
  repo_name = url.split('/').last(2).join("/")

  client = Octokit::Client.new access_token: access_token

  release_options = {
    draft: true,
    name: gemspec.version,
    body: "Release #{gemspec.version}"
  }

  release = client.create_release repo_name, name, release_options
  puts "uploading assets"
  client.upload_asset release.url, "pkg/#{name}", {content_type: "application/x-gzip" }
  puts "publishing.."
  client.update_release release.url, {draft: false}
  puts "done"
end


# # #
# Start an IRB session with the gem loaded

desc "#{gemspec.name} | IRB"
task :irb do
  sh "irb -I ./lib -r #{gemspec.name.gsub '-','/'}"
end
