# frozen_string_literal: true

require 'test_helper'

class ConnectionManagementTest < Minitest::Test
  def test_connection_management
    assert_predicate conn, :active?

    conn.disconnect!

    refute_predicate conn, :active?

    conn.disconnect!

    refute_predicate conn, :active?

    conn.reconnect!

    assert_predicate conn, :active?
  ensure
    conn.reconnect!
  end

  private

  def conn
    ActiveRecord::Base.connection
  end
end
