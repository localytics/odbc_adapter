# frozen_string_literal: true

require 'test_helper'

class AttributesTest < Minitest::Test
  def test_booleans?
    assert_predicate Todo.first, :published?
    refute_predicate Todo.last, :published?
  end

  def test_integers
    assert_kind_of Integer, User.first.letters
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
