require_relative "../lib/wooget"
require "minitest/autorun"

class UnityTests < Minitest::Test
  def bootstrap_existing_dependencies_test
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do

      end
    end
  end
end