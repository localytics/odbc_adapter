# frozen_string_literal: true

require 'test_helper'

class MigrationsTest < Minitest::Test
  def setup
    @connection = User.connection
  end

  def test_table_crud
    @connection.create_table(:foos, force: true) do |t|
      t.timestamps null: false
    end

    assert_equal 3, @connection.columns(:foos).count

    @connection.rename_table(:foos, :bars)

    assert_equal 3, @connection.columns(:bars).count

    @connection.drop_table(:bars)
  end

  def test_column_crud
    previous_count = @connection.columns(:users).count

    @connection.add_column(:users, :foo, :integer)

    assert_equal previous_count + 1, @connection.columns(:users).count

    @connection.rename_column(:users, :foo, :bar)

    assert_equal previous_count + 1, @connection.columns(:users).count

    @connection.remove_column(:users, :bar)

    assert_equal previous_count, @connection.columns(:users).count
  end
end
