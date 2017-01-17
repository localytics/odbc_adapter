require 'test_helper'

class CRUDTest < ODBCTest
  def test_creation
    User.create(first_name: 'foo', last_name: 'bar')
    assert_equal 7, User.count
  end

  def test_update
    user = User.first
    user.letters = 47
    user.save!

    assert_equal 47, user.reload.letters
  end

  def test_destroy
    User.first.destroy
    assert_equal 5, User.count
  end
end
