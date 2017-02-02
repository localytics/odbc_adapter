require 'test_helper'

class RegistryTest < Minitest::Test
  def test_register
    registry = ODBCAdapter::Registry.new

    require File.join('odbc_adapter', 'adapters', 'mysql_odbc_adapter')
    registry.register(/foobar/, ODBCAdapter::Adapters::MySQLODBCAdapter) do
      def initialize
      end

      def quoted_true
        'foobar'
      end
    end

    adapter = registry.adapter_for('Foo Bar')
    assert_kind_of Class, adapter
    assert_equal ODBCAdapter::Adapters::MySQLODBCAdapter, adapter.superclass
    assert_equal 'foobar', adapter.new.quoted_true
  end
end
