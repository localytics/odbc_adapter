require 'test_helper'

class ConnectionStringTest < Minitest::Test
  def setup; end

  def teardown; end

  # Make sure that the connection string is parsed properly when it has an equals sign
  def test_odbc_conn_str_connection_with_equals
    conn_str = 'Foo=Bar;Foo2=Something=with=equals'

    odbc_driver_instance_mock = Minitest::Mock.new
    odbc_database_instance_mock = Minitest::Mock.new
    odbc_connection_instance_mock = Minitest::Mock.new

    # Setup ODBC::Driver instance mocks
    odbc_driver_instance_mock.expect(:name=, nil, ['odbc'])
    odbc_driver_instance_mock.expect(:attrs=, nil, [{ 'Foo' => 'Bar', 'Foo2' => 'Something=with=equals' }])

    # Setup ODBC::Database instance mocks
    odbc_database_instance_mock.expect(:drvconnect, odbc_connection_instance_mock, [odbc_driver_instance_mock])

    # Stub ODBC::Driver.new
    ODBC::Driver.stub :new, odbc_driver_instance_mock do
      # Stub ODBC::Database.new
      ODBC::Database.stub :new, odbc_database_instance_mock do
        # Run under our stubs/mocks
        ActiveRecord::Base.__send__(:odbc_conn_str_connection, conn_str: conn_str)
      end
    end

    # make sure we called the methods we expected
    odbc_driver_instance_mock.verify
    odbc_database_instance_mock.verify
    odbc_connection_instance_mock.verify
  end

  # Make sure that the connection string is parsed properly when it doesn't have an
  # equals sign
  def test_odbc_conn_str_connection_without_equals
    conn_str = 'Foo=Bar;Foo2=Something without equals'

    odbc_driver_instance_mock = Minitest::Mock.new
    odbc_database_instance_mock = Minitest::Mock.new
    odbc_connection_instance_mock = Minitest::Mock.new

    # Setup ODBC::Driver instance mocks
    odbc_driver_instance_mock.expect(:name=, nil, ['odbc'])
    odbc_driver_instance_mock.expect(:attrs=, nil, [{ 'Foo' => 'Bar', 'Foo2' => 'Something without equals' }])

    # Setup ODBC::Database instance mocks
    odbc_database_instance_mock.expect(:drvconnect, odbc_connection_instance_mock, [odbc_driver_instance_mock])

    # Stub ODBC::Driver.new
    ODBC::Driver.stub :new, odbc_driver_instance_mock do
      # Stub ODBC::Database.new
      ODBC::Database.stub :new, odbc_database_instance_mock do
        # Run under our stubs/mocks
        ActiveRecord::Base.__send__(:odbc_conn_str_connection, conn_str: conn_str)
      end
    end

    # make sure we called the methods we expected
    odbc_driver_instance_mock.verify
    odbc_database_instance_mock.verify
    odbc_connection_instance_mock.verify
  end
end
