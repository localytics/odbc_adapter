require 'test_helper'

class CalculationsTest < ODBCTest
  def test_count
    assert_equal 6, User.count
  end

  def test_average
    assert_equal 10.33, User.average(:letters).round(2)
  end
end
