require 'test_helper'

class ODBCAdapterTest < Minitest::Test
  def test_version
    refute_nil ODBCAdapter::VERSION
  end
end
