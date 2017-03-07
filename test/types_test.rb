require 'test_helper'

class TypesTest < Minitest::Test
  def test_user_types
    assert_types(
      User.first,
      first_name: String,
      last_name: String,
      letters: Integer,
      created_at: Time,
      updated_at: Time
    )
  end

  def test_todo_types
    assert_types(
      Todo.first,
      user_id: Integer,
      body: String,
      published: [TrueClass, FalseClass],
      created_at: Time,
      updated_at: Time
    )
  end

  private

  def assert_types(model, expected)
    expected.each do |column, types|
      value   = model.public_send(column)
      allowed = Array(types)

      assert allowed.any? { |type| value.is_a?(type) },
             "Expected #{model.class.name}##{column} to be one of " \
             "#{allowed.inspect} but got a #{value.class.name}"
    end
  end
end
