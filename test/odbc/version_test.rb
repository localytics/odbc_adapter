require 'test_helper'

class ODBC::AdapterTest < Minitest::Test
  def test_version
    refute_nil ::ODBC::Adapter::VERSION
  end
end
