require 'test_helper'

class ConnectionFailTest < Minitest::Test
  def test_connection_fail
    # We're only interested in testing a MySQL connection failure for now.
    # Postgres disconnects generate a different class of errors
    skip 'Only executed for MySQL' unless ActiveRecord::Base.connection.instance_values['config'][:conn_str].include? 'MySQL'
    begin
      conn.execute('KILL CONNECTION_ID();')
    rescue => e
      puts "caught exception #{e}"
    end
    assert_raises(ODBCAdapter::ConnectionFailedError) { User.average(:letters).round(2) }
  end

  def conn
    ActiveRecord::Base.connection
  end
end
