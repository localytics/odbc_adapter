require 'odbc_adapter/snowflake/schema_statements'

module ODBCAdapter
  module Adapters
    # An adapter for use with Snowflake via ODBC
    class SnowflakeODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      include ODBCAdapter::Snowflake::SchemaStatements

      def prepared_statements
        true
      end
    end
  end
end
