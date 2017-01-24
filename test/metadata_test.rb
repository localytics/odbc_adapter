require 'test_helper'

class MetadataTest < Minitest::Test
  def test_tables
    assert_equal %w[ar_internal_metadata todos users], User.connection.tables.sort
  end

  def test_column_names
    expected = %w[created_at first_name id last_name letters updated_at]
    assert_equal expected, User.column_names.sort
  end

  def test_primary_key
    assert_equal 'id', User.connection.primary_key('users')
  end
end
