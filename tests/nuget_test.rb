require_relative "../lib/wooget"
require "minitest/autorun"

SINGLE_NUGET_ELEMENT = File.join(File.dirname(__FILE__),"nuget_package.xml")
NUGET_FEED = File.join(File.dirname(__FILE__),"nuget_feed.xml")

class NugetTest < Minitest::Test
  def test_parse_single_element
    packages = Wooget::Nuget.from_xml(File.open(SINGLE_NUGET_ELEMENT))

    assert_equal( 1, packages.count, "Should be one valid package returned")
    assert_equal("Unit.Test.Package.Name", packages.first.package_id, "package id should be set to xml value")
    assert_equal("7.7.777", packages.first.version, "package version should be set to xml value")
    assert_equal("https://lol.test.url", packages.first.url, "package url should be set to xml value")
  end

  def test_parse_nuget_feed
    packages = Wooget::Nuget.from_xml(File.open(NUGET_FEED))

    assert_equal( 80, packages.count, "Should be 80 packages")

    ids = packages.map{|p| p.package_id}
    ids.compact!

    assert_equal( 80, ids.count, "Should be 80 unique package ids")
  end
end