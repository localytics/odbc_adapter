require 'test_helper'

class ConnectionManagementTest < Minitest::Test
  def test_connection_management
    assert conn.active?

    conn.disconnect!
    refute conn.active?

    conn.disconnect!
    refute conn.active?

    conn.reconnect!
    assert conn.active?
  ensure
    conn.reconnect!
  end

  private

  def conn
    ActiveRecord::Base.connection
  end
end
