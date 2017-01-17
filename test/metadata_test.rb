require 'test_helper'

class MetadataTest < Minitest::Test
  def test_tables
    assert_equal %w[users], User.connection.tables
  end
end
