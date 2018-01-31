require 'test_helper'

# Dummy class for this test
class ConnectionsTestDummyActiveRecordModel < ActiveRecord::Base
  self.abstract_class = true
end

# This test makes sure that all of the connection methods work properly
class ConnectionsTest < Minitest::Test
  def setup
    @options = { adapter: 'odbc' }
    @options[:conn_str] = ENV['CONN_STR'] if ENV['CONN_STR']
    @options[:dsn]      = ENV['DSN'] if ENV['DSN']
    @options[:dsn]      = 'ODBCAdapterPostgreSQLTest' if @options.values_at(:conn_str, :dsn).compact.empty?

    ConnectionsTestDummyActiveRecordModel.establish_connection @options

    @connection = ConnectionsTestDummyActiveRecordModel.connection
  end

  def teardown
    @connection.disconnect!
  end

  def test_active?
    assert_equal @connection.raw_connection.connected?, @connection.active?
  end

  def test_disconnect!
    @raw_connection = @connection.raw_connection

    assert_equal true, @raw_connection.connected?
    @connection.disconnect!
    assert_equal false, @raw_connection.connected?
  end

  def test_reconnect!
    @old_raw_connection = @connection.raw_connection
    assert_equal true, @connection.active?
    @connection.reconnect!
    refute_equal @old_raw_connection, @connection.raw_connection
  end
end