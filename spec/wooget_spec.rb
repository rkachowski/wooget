require_relative "../lib/wooget"
require "minitest/autorun"

describe Wooget do

  it "should create a new package tree" do
    Dir.mktmpdir do |tmpdir|

      Dir.chdir(tmpdir) do
        Wooget::Project.new.create "Cool.Test.Package", author: "Test Author", repo: "testrepo", quiet:true

        assert Dir.exists?("Cool.Test.Package"), "Dir should have been created for package"
        assert File.exists?(File.join("Cool.Test.Package", "paket.template")), "template should have been made for package"
        assert File.exists?(File.join("Cool.Test.Package", "paket.dependencies")), "dependencies should have been made for package"

        #todo: assert that package can be built
      end
    end
  end

  it "should correctly format prerelease files" do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
         Wooget::Project.new.create "Prerelease.Package", author: "Test Author", repo: "testrepo", visual_studio: true, quiet:true

        #put a release dependency at the end of the template
        `echo "dependencies" >> Prerelease.Package/paket.template`
        `echo "    test.dependency.package" >> Prerelease.Package/paket.template`

        #put a release dependency in the paket.dependencies file
        `echo "nuget test.dependency.package" >>  Prerelease.Package/paket.dependencies`

        #set version to prerelease for tests
        lines = File.open(File.join("Prerelease.Package", "RELEASE_NOTES.md")).each_line.to_a
        lines.unshift "### 99.99.99-prerelease "
        File.open(File.join("Prerelease.Package", "RELEASE_NOTES.md"),"w"){|f| f << lines.join }


        Dir.chdir("Prerelease.Package") do
          Wooget::Releaser.new.prerelease :no_push => true, :quiet => true
        end

        template_contents = File.open(File.join("Prerelease.Package", "paket.template")).read
        dependencies_contents = File.open(File.join("Prerelease.Package", "paket.dependencies")).read

        assert template_contents.include?("test.dependency.package >= 0.0.0-prerelease"), "template should have prerelease dependencies with version spec"
        assert dependencies_contents.include?("nuget test.dependency.package prerelease"), "dependencies file should have package marked as prerelease"

      end
    end
  end

  it "should update metadatafiles correctly" do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        proj = Wooget::Project.new
        proj.options = { source_folder: "DoesntMatter" , quiet: true}
        proj.template("metafile.cs.erb", "TestFile_meta.cs")

        assert File.exists?("TestFile_meta.cs"), "Test file should have been created"

        releaser = Wooget::Releaser.new
        releaser.update_metadata "1.2.3-testversion"

        file_contents = File.open("TestFile_meta.cs").read
        assert (file_contents =~ /1.2.3-testversion/), "1.2.3-testversion should be in the metafile"
        assert !(file_contents =~ /0.0.0/), "0.0.0 (default version) shouldn't be in the metafile anymore"
      end
    end
  end
end

