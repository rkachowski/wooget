require_relative "../lib/wooget"
require "minitest/autorun"

describe Wooget do

  it "should create a new package tree" do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        Wooget.create "Cool.Test.Package", author: "Test Author", repo: "testrepo"

        assert Dir.exists?("Cool.Test.Package"), "Dir should have been created for package"
        assert File.exists?(File.join("Cool.Test.Package", "paket.template")), "template should have been made for package"
        assert File.exists?(File.join("Cool.Test.Package", "paket.dependencies")), "dependencies should have been made for package"

        #todo: assert that package can be built
      end
    end
  end


end

