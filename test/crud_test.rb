require 'test_helper'

class CRUDTest < Minitest::Test
  def test_creation
    with_transaction do
      User.create(first_name: 'foo', last_name: 'bar')
      assert_equal 7, User.count
    end
  end

  def test_update
    with_transaction do
      user = User.first
      user.letters = 47
      user.save!

      assert_equal 47, user.reload.letters
    end
  end

  def test_destroy
    with_transaction do
      User.last.destroy
      assert_equal 5, User.count
    end
  end

  private

  def with_transaction(&_block)
    User.transaction do
      yield
      raise ActiveRecord::Rollback
    end
  end
end
