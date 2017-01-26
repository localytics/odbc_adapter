require 'test_helper'

class AttributesTest < Minitest::Test
  def test_booleans?
    skip 'Querying booleans not functioning properly yet'
    assert_equal true, Todo.first.published?
    assert_equal false, Todo.last.published?
  end

  def test_integers
    assert_kind_of Fixnum, User.first.letters
  end

  def test_strings
    assert_kind_of String, User.first.first_name
    assert_kind_of String, Todo.first.body
  end

  def test_attributes
    assert_kind_of Hash, User.first.attributes
    assert_kind_of Hash, Todo.first.attributes
  end
end
